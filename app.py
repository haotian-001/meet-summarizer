import gradio as gr
import docx
import requests
import pandas as pd
from docxtpl import DocxTemplate
import io
import logging
import os
import tempfile
import json
import re
import datetime

# test for new push No.4

# 设置日志
logging.basicConfig(level=logging.DEBUG, format='%(asctime)s - %(levelname)s - %(message)s')

# 提取Word文档中的文本
def extract_text_from_docx(file):
    logging.debug("开始从Word文档提取文本")
    doc = docx.Document(file.name)  # 使用 file.name 获取文件路径
    full_text = [para.text for para in doc.paragraphs]
    extracted_text = '\n'.join(full_text)
    logging.debug(f"提取的文本长度: {len(extracted_text)} 字符")
    return extracted_text

# 调用LLM API，添加系统提示
def call_llm_api(text, model, manual_agenda=None):
    logging.debug(f"开始调用LLM API，使用模型: {model}")
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {os.environ.get('OPENROUTER_API_KEY')}",
        "Content-Type": "application/json"
    }
    system_prompt = (
        "你是一个专业的会议纪要生成���手。请提取会议中的关键信息和共识。"
        f"{'如果提供了会议议题，请按照给定的议题来组织内容。' if manual_agenda else '请从会议内容中提取主要议题。'}"
        
        "你的输出必须是严格的JSON格式，包含以下键值对："
        "\"开始时间\": \"字符串\", "
        "\"结束时间\": \"字符串\", "
        "\"参加人员\": [\"人名1\", \"人名2\", ...], "
        "\"主持人\": \"人名\", "
        "\"议题讨论\": ["
        "    {"
        "        \"议题\": \"议题名称\", "
        "        \"共识\": \"该议题达成的共识和结论\""
        "    }"
        "], "
        "\"后续工作\": ["
        "    {"
        "        \"任务\": \"具体工作内容\", "
        "        \"负责人\": \"人名\", "
        "        \"截止时间\": \"YYYY-MM-DD\""
        "    }"
        "]"
        
        "处理要求："
        "1. 每个议题只提取最终达成的共识和结论\n"
        "2. 所有具体的行动事项统一放在后续工作中\n"
        "3. 如果信息不完整，使用\"待定\"代替\n"
        "4. JSON必须放在 ```json 和 ``` 之间\n"
    )
    user_prompt = f"会议议题：{manual_agenda}\n\n原始记录：{text}" if manual_agenda else text

    data = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    }
    response = requests.post(url, json=data, headers=headers)
    
    if response.status_code != 200:
        logging.error(f"API调用失败。状态码: {response.status_code}, 响应内容: {response.text}")
        raise Exception(f"API调用失败: {response.status_code} - {response.text}")
    
    response_json = response.json()
    if 'choices' not in response_json:
        logging.error(f"API响应中没有'choices'键。完整响应: {response_json}")
        raise Exception("API响应格式不正确")
    
    api_content = response_json['choices'][0]['message']['content']
    logging.debug(f"API返回原始内容: {api_content}")
    
    # 使用正则表达式提取```json和```之间的内容
    json_match = re.search(r'```json\s*(.*?)\s*```', api_content, re.DOTALL)
    if json_match:
        api_content = json_match.group(1)
        logging.debug(f"提取的JSON内容: {api_content}")
    else:
        logging.error("未能从API响应中提取JSON内容")
        raise Exception("API响应中没有有效的JSON数据")
    
    # 移除可能的代码块标记（以防万一）
    api_content = api_content.strip()
    if api_content.startswith('```') and api_content.endswith('```'):
        api_content = api_content[3:-3].strip()
    if api_content.startswith('```json'):
        api_content = api_content[7:].strip()
    
    try:
        api_result = json.loads(api_content)
        logging.debug(f"解析后的JSON数据: {api_result}")
    except json.JSONDecodeError as e:
        logging.error(f"解析JSON失败: {e}")
        raise Exception("API返回的内容不是有效的JSON格式")
    
    # 验证JSON结构
    required_keys = ["开始时间", "结束时间", "参加人员", "主持人", "议题讨论", "后续工作"]
    for key in required_keys:
        if key not in api_result:
            logging.error(f"JSON数据中缺少关键字段: {key}")
            raise Exception(f"JSON数据中缺少关键字段: {key}")

    return api_result

# 使用JSON数据填充Word模板
def fill_word_template(data, original_filename):
    logging.debug("开始填充Word模板")
    template_path = "templates/template.docx"
    doc = DocxTemplate(template_path)
    
    # Extract filename without extension from the full path
    filename = os.path.splitext(os.path.basename(original_filename))[0]
    
    context = {
        "start_time": data["开始时间"],
        "end_time": data["结束时间"],
        "participants": data["参加人员"],
        "host": data["主持人"],
        "agenda": data["议题讨论"],
        "action_items": data["后续工作"],
        "current_time": datetime.datetime.now().strftime("%Y-%m-%d"),
        "original_filename": filename  # Use filename without extension
    }

    doc.render(context)
    
    # Get the original filename without extension
    base_name = os.path.splitext(os.path.basename(original_filename))[0]
    # Create output filename
    output_filename = f"{base_name}.docx"
    
    # Create temporary file with the desired filename
    temp_dir = tempfile.gettempdir()
    output_path = os.path.join(temp_dir, output_filename)
    doc.save(output_path)
    
    logging.debug(f"填充后的Word文档已保存到临时文件: {output_path}")
    return output_path

# 修改 process_file 函数
def process_file(file, model, use_ai_agenda, manual_agenda=None):
    logging.debug(f"开始处理上传的文件，选择的模型: {model}")
    
    if file is None:
        return None
    
    if not file.name.lower().endswith('.docx'):
        return None

    text = extract_text_from_docx(file)
    
    # 根据开关状态决定是否使用手动输入的议题
    if not use_ai_agenda and manual_agenda:
        # 将手动输入的议题添加到文本中
        text = f"会议议题：{manual_agenda}\n\n{text}"
    
    api_result = call_llm_api(text, model, manual_agenda)
    
    # 在后台进行反思和改进，并记录反思过程
    improved_summary, reflection_process = reflect_and_improve(text, api_result, model)
    logging.info(f"反思过程:\n{reflection_process}")
    
    word_file_path = fill_word_template(improved_summary, file.name)
    
    logging.debug("文件处理完成")
    return word_file_path

# 反思和改进会议纪要
def reflect_and_improve(original_text, generated_summary, model):
    logging.debug("开始反思和改进会议纪要")
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = {
        "Authorization": f"Bearer {os.environ.get('OPENROUTER_API_KEY')}",
        "Content-Type": "application/json"
    }
    system_prompt = (
        "你是一个专业的会议纪要审核助手。你的任务是仔细比较原始会议记录和生成的会议纪要，"
        "检查是否存在错误、遗漏或不准确的信息。请特别注意以下几点：\n"
        "1. 确保所有重要的议题都被涵盖\n"
        "2. 验证参会人员信息的准确性\n"
        "3. 检查会议开始和结束时间是否正确\n"
        "4. 确保关键决策和行动项目都被准确记录\n"
        "5. 验证发言内容的准确性和完整性\n"
        "6. 对于后续工作中的待办事项，如果截止时间或负责人为空，请将对应的值改为\"TBD\"\n\n"
        "首先，请详细说��你的反思过程和发现的问题。然后，如果发现任何问题，"
        "请直接在原有的JSON结构中修改相应的内容。不要改变JSON的结构，只更新内容。"
        "你的最终输出应该包含两部分：\n"
        "1. 反思过程和发现的问题\n"
        "2. 一个完整的、改进后的会议纪要JSON对象，结构与输入的JSON完全相同\n"
        "请将反思过程放在 ```reflection 和 ``` 之间，将生成的JSON放在 ```json 和 ``` 之间的代码块中。"
        "例如：\n```reflection\n反思过程...\n```\n```json\n{\"key\": \"value\"}\n```"
        "确保JSON可以被标准的JSON解析器直接处理。"
    )
    user_prompt = f"原始会议记录：\n\n{original_text}\n\n生成的会议纪要：\n\n{json.dumps(generated_summary, ensure_ascii=False, indent=2)}"

    data = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ]
    }
    response = requests.post(url, json=data, headers=headers)
    
    if response.status_code != 200:
        logging.error(f"反思API调用失败。状态码: {response.status_code}, 响应内容: {response.text}")
        raise Exception(f"反思API调用���败: {response.status_code} - {response.text}")
    
    reflection_result = response.json()['choices'][0]['message']['content']
    logging.debug(f"API返回原始内容: {reflection_result}")
    
    # 提取反思过程
    reflection_match = re.search(r'```reflection\s*(.*?)\s*```', reflection_result, re.DOTALL)
    reflection_process = reflection_match.group(1) if reflection_match else "未找到反思过程"
    
    # 提取改进后的JSON
    json_match = re.search(r'```json\s*(.*?)\s*```', reflection_result, re.DOTALL)
    if json_match:
        improved_json = json_match.group(1)
    else:
        logging.error("未能从API响应中提取JSON内容")
        raise Exception("API响应中没有有效的JSON数据")
    
    try:
        improved_summary = json.loads(improved_json)
        logging.debug(f"改进后的JSON数据: {improved_summary}")
        logging.debug(f"反思过程: {reflection_process}")
        return improved_summary, reflection_process
    except json.JSONDecodeError as e:
        logging.error(f"解析反思结果JSON失败: {e}")
        raise Exception("反思API返回的内容不是有效的JSON格式")

# 更新 Gradio 界面
with gr.Blocks() as iface:
    gr.Markdown("# 会议纪要生成助手")
    gr.Markdown("上传钉钉导出的会议原始记录的 Word 文件（.docx 格式），选择模型，生成会议纪要 Word 文件。")
    gr.Markdown("**注意：** AI 可能会犯错或者遗漏，请仔细检查生成的会议纪要。")
    # Add build time information
    import datetime
    
    build_time = gr.Markdown(f"版本日期: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    with gr.Row():
        file_input = gr.File(label="上传 Word 文件")
        model_dropdown = gr.Dropdown(
            choices=[
                "google/gemini-2.5-flash",
                "google/gemini-pro-1.5",
                # "anthropic/claude-3.5-sonnet",
                # "qwen/qwen-2.5-72b-instruct",
                # "openai/gpt-4o-2024-08-06"
            ],
            label="选择模型",
            value="google/gemini-2.5-flash"
        )
    
    use_ai_agenda = gr.Checkbox(label="使用 AI 自动生成议题", value=True)
    manual_agenda = gr.Textbox(
        label="手动输入会议议题",
        visible=False
    )
    
    use_ai_agenda.change(
        fn=lambda x: gr.update(visible=not x),
        inputs=use_ai_agenda,
        outputs=manual_agenda
    )
    
    submit_button = gr.Button("生成会议纪要")
    output_file = gr.File(label="下载生成的会议纪要")
    
    submit_button.click(
        fn=process_file,
        inputs=[file_input, model_dropdown, use_ai_agenda, manual_agenda],
        outputs=output_file
    )

if __name__ == "__main__":
    logging.debug("启动Gradio界面")
    iface.launch(server_name="0.0.0.0", share=True)