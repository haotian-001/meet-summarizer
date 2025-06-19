# 会议纪要生成助手 ⚡

一个基于AI的智能会议纪要生成工具，能够将会议原始记录转换为结构化的会议纪要文档。支持钉钉等平台导出的会议记录，使用先进的大语言模型进行智能处理和自我反思优化。

## 功能特性

- 📝 **智能摘要生成**: 将原始会议记录转换为结构化的会议纪要
- 🤖 **多模型支持**: 支持Google Gemini 2.5 Flash、Gemini Pro 1.5等先进的大语言模型
- 📄 **Word文档处理**: 上传.docx格式文件，生成格式化的会议纪要Word文档
- 🎯 **灵活议题管理**: 支持AI自动提取议题或手动输入会议议题
- 🔄 **自我反思优化**: AI会审查并改进自己的输出，提高准确性和完整性
- ⚡ **快速部署**: 使用uv包管理器进行快速部署和依赖管理
- 🌐 **代理支持**: 内置网络代理配置，适合企业环境部署
- 📊 **结构化输出**: 自动提取参会人员、议题讨论、后续工作等关键信息

## 快速开始

### 系统要求

- Python 3.8+
- uv包管理器（推荐）
- OpenRouter API密钥（用于访问AI模型）

### 一键部署（推荐）

1. **克隆仓库**:
   ```bash
   git clone <repository-url>
   cd meet-summarizer
   ```

2. **安装uv包管理器**（如果尚未安装）:
   ```bash
   curl -LsSf https://astral.sh/uv/install.sh | sh
   ```

3. **一键部署**:
   ```bash
   ./deploy.sh
   ```

   首次运行时，脚本会自动创建`.env`模板文件。请编辑该文件并添加你的OpenRouter API密钥：
   ```bash
   # 编辑.env文件
   OPENROUTER_API_KEY=your_actual_api_key_here
   ```

   然后重新运行部署脚本：
   ```bash
   ./deploy.sh
   ```

4. **访问应用**:
   在浏览器中打开 `http://localhost:7860`

### 手动部署（备选方案）

如果你不想使用自动部署脚本：

1. **创建虚拟环境**:
   ```bash
   uv venv .venv
   source .venv/bin/activate  # Linux/macOS
   # 或者 .venv\Scripts\activate  # Windows
   ```

2. **安装依赖**:
   ```bash
   uv pip install -r requirements.txt
   ```

3. **配置环境变量**:
   ```bash
   # 创建.env文件
   echo "OPENROUTER_API_KEY=your_actual_api_key_here" > .env
   ```

4. **运行应用**:
   ```bash
   python app.py
   ```

## 使用方法

1. **上传会议记录**: 上传包含会议原始记录的.docx格式文件（支持钉钉等平台导出的文件）
2. **选择AI模型**: 从可用模型中选择（推荐使用Google Gemini 2.5 Flash）
3. **配置议题**: 选择使用AI自动提取议题或手动输入会议议题
4. **生成纪要**: 点击"生成会议纪要"按钮开始处理
5. **下载结果**: 下载生成的格式化会议纪要Word文档

## 应用管理

### 可用脚本

- `./deploy.sh` - 使用uv部署应用程序
- `./stop.sh` - 停止运行中的应用程序

### 管理命令

```bash
# 查看应用日志
tail -f /tmp/meet-summarizer.log

# 停止应用
./stop.sh

# 或者手动停止
pkill -f "python.*app.py"

# 检查端口占用
lsof -i:7860
```

## 配置说明

### 环境变量

创建`.env`文件并配置以下变量：

```env
# 必需：OpenRouter API密钥，用于访问AI模型
OPENROUTER_API_KEY=your_actual_api_key_here
```

部署脚本会自动设置以下运行时环境变量：
- `GRADIO_SERVER_NAME=0.0.0.0`
- `GRADIO_SERVER_PORT=7860`
- `PYTHONUNBUFFERED=1`
- 代理设置（如果需要）

### 支持的AI模型

- `google/gemini-2.5-flash` (默认，推荐)
- `google/gemini-pro-1.5`
- 可在`app.py`中配置其他模型

## 项目结构

```
meet-summarizer/
├── app.py                 # 主应用程序文件
├── requirements.txt       # Python依赖包列表
├── deploy.sh             # 自动部署脚本
├── stop.sh               # 应用停止脚本
├── templates/            # Word文档模板目录
│   └── template.docx     # 会议纪要模板文件
├── .env                  # 环境变量配置文件（需要创建）
└── .venv/                # 虚拟环境目录（自动创建）
```

## 故障排除

### 常见问题

1. **端口被占用**:
   ```bash
   # 终止占用7860端口的进程
   lsof -ti:7860 | xargs kill -9
   ```

2. **uv未安装**:
   ```bash
   # 安装uv包管理器
   curl -LsSf https://astral.sh/uv/install.sh | sh
   # 重新加载shell配置
   source ~/.bashrc  # 或 source ~/.zshrc
   ```

3. **应用无法启动**:
   ```bash
   # 检查应用日志
   tail -f /tmp/meet-summarizer.log

   # 检查.env文件是否存在且配置正确
   cat .env
   ```

4. **API密钥问题**:
   - 确保OpenRouter API密钥有效
   - 检查`.env`文件中的密钥配置是否正确
   - 验证API密钥是否有足够的额度

5. **网络连接问题**:
   - 如果在企业环境中，检查代理设置
   - 确保能够访问`openrouter.ai`

### 日志和调试

```bash
# 查看实时日志
tail -f /tmp/meet-summarizer.log

# 查看最近的日志
tail -50 /tmp/meet-summarizer.log

# 检查应用进程状态
ps aux | grep "python.*app.py"
```

## 开发指南

### 本地开发

1. **设置虚拟环境**:
   ```bash
   uv venv .venv
   source .venv/bin/activate  # Linux/macOS
   # 或者 .venv\Scripts\activate  # Windows
   ```

2. **安装依赖**:
   ```bash
   uv pip install -r requirements.txt
   ```

3. **开发模式运行**:
   ```bash
   python app.py
   ```

### 自定义配置

如需修改应用配置，可以编辑以下文件：
- `app.py` - 主应用逻辑和模型配置
- `templates/template.docx` - 会议纪要Word模板
- `deploy.sh` - 部署脚本配置

### 添加新的AI模型

在`app.py`中的模型下拉列表中添加新模型：
```python
model_dropdown = gr.Dropdown(
    choices=[
        "google/gemini-2.5-flash",
        "google/gemini-pro-1.5",
        "your-new-model-here"  # 添加新模型
    ],
    # ...
)
```

## 技术特性

### AI处理流程

1. **文本提取**: 从上传的Word文档中提取原始会议记录
2. **智能分析**: 使用大语言模型分析会议内容，提取关键信息
3. **结构化输出**: 生成包含时间、人员、议题、共识、后续工作的JSON结构
4. **自我反思**: AI审查并改进初次生成的结果
5. **模板填充**: 使用改进后的数据填充Word模板生成最终文档

### 输出格式

生成的会议纪要包含以下结构化信息：
- 开始时间和结束时间
- 参加人员列表
- 主持人信息
- 议题讨论（每个议题的共识和结论）
- 后续工作（具体任务、负责人、截止时间）

## 许可证

Apache License 2.0 - 详见LICENSE文件。

## 支持

如有问题或疑问：
1. 查看上述故障排除部分
2. 检查应用日志中的错误信息
3. 确保所有前置条件都已正确安装
4. 验证环境变量配置是否正确
5. 确认OpenRouter API密钥有效且有足够额度
