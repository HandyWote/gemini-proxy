@echo off
REM Gemini代理项目测试脚本 - Windows批处理版本
REM 用于测试Cloudflare Worker代理的Gemini API功能

setlocal enabledelayedexpansion

REM 颜色定义
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "NC=[0m"

REM 默认配置
set "DEFAULT_BASE_URL=http://localhost:8787"
set "DEFAULT_API_KEY=your-gemini-api-key-here"

REM 帮助信息
:show_help
echo 使用方法: %0 [选项]
echo.
echo 选项:
echo   -u URL        设置代理服务器URL (默认: %DEFAULT_BASE_URL%)
echo   -k KEY        设置Gemini API密钥
echo   -h            显示此帮助信息
echo.
echo 示例:
echo   %0 -k your-actual-api-key
echo   %0 -u http://your-worker.your-subdomain.workers.dev -k your-api-key
goto :eof

REM 解析命令行参数
set "BASE_URL=%DEFAULT_BASE_URL%"
set "API_KEY=%DEFAULT_API_KEY%"

:parse_args
if "%~1"=="" goto :continue
if "%~1"=="-h" goto :show_help
if "%~1"=="-u" (
    set "BASE_URL=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="-k" (
    set "API_KEY=%~2"
    shift
    shift
    goto :parse_args
)
echo 未知选项: %~1
goto :show_help

:continue
if "%API_KEY%"=="%DEFAULT_API_KEY%" (
    echo %YELLOW%警告: 使用默认API密钥，请使用 -k 参数提供真实的API密钥%NC%
)

echo %BLUE%=== Gemini代理测试脚本 ===%NC%
echo 代理服务器: %GREEN%%BASE_URL%%NC%
echo 测试时间: %date% %time%
echo.

REM 测试计数器
set "TESTS_PASSED=0"
set "TESTS_FAILED=0"
set "TOTAL_TESTS=0"

REM 测试函数
:run_test
set "test_name=%~1"
set "curl_command=%~2"
set "expected_status=%~3"

set /a TOTAL_TESTS+=1
echo %BLUE%测试: %test_name%%NC%

REM 执行curl命令并获取状态码
for /f "tokens=*" %%a in ('%curl_command% -w "STATUS_CODE:%%{http_code}" -s') do (
    set "full_response=%%a"
)

REM 提取状态码
for /f "tokens=2 delims=:" %%b in ("%full_response%") do (
    set "status_code=%%b"
)

REM 提取响应体（移除状态码行）
set "response=%full_response:STATUS_CODE:%=%"

if "%status_code%"=="%expected_status%" (
    echo %GREEN%√ 通过%NC% (状态码: %status_code%)
    set /a TESTS_PASSED+=1
) else (
    echo %RED%× 失败%NC% (期望: %expected_status%, 实际: %status_code%)
    echo 响应: %response%
)
echo.
goto :eof

REM 测试1: CORS预检请求
echo %YELLOW%=== 测试1: CORS预检请求 ===%NC%
call :run_test "OPTIONS请求" "curl -s -X OPTIONS %BASE_URL%" "200"

REM 测试2: 无认证头的请求
echo %YELLOW%=== 测试2: 无认证头请求 ===%NC%
call :run_test "无认证头" "curl -s %BASE_URL%" "401"

REM 测试3: 无效的认证格式
echo %YELLOW%=== 测试3: 无效认证格式 ===%NC%
call :run_test "无效认证格式" "curl -s -H ""Authorization: InvalidFormat"" %BASE_URL%" "401"

REM 测试4: 有效的认证头但无效的API密钥
echo %YELLOW%=== 测试4: 有效格式但无效密钥 ===%NC%
call :run_test "有效格式无效密钥" "curl -s -H ""Authorization: Bearer invalid-key"" %BASE_URL%" "401"

REM 测试5: 测试/chat/completions端点
echo %YELLOW%=== 测试5: 测试聊天完成端点 ===%NC%
set /a TOTAL_TESTS+=1
echo %BLUE%测试: 聊天完成端点%NC%

for /f "tokens=*" %%a in ('curl -s -w "STATUS_CODE:%%{http_code}" -X POST -H "Authorization: Bearer %API_KEY%" -H "Content-Type: application/json" -d "{""model"":""gemini-1.5-flash"",""messages"":[{""role"":""user"",""content"":""Hello""}],""max_tokens"":10}" %BASE_URL%/chat/completions') do (
    set "chat_response=%%a"
)

for /f "tokens=2 delims=:" %%b in ("%chat_response%") do (
    set "chat_status=%%b"
)
set "chat_body=%chat_response:STATUS_CODE:%=%"

if "%chat_status:~0,1%"=="2" (
    echo %GREEN%√ 通过%NC% (状态码: %chat_status%)
    set /a TESTS_PASSED+=1
) else (
    echo %RED%× 失败%NC% (状态码: %chat_status%)
    echo 响应: %chat_body%
)
echo.

REM 测试6: 测试/models端点
echo %YELLOW%=== 测试6: 测试模型列表端点 ===%NC%
set /a TOTAL_TESTS+=1
echo %BLUE%测试: 模型列表端点%NC%

for /f "tokens=*" %%a in ('curl -s -w "STATUS_CODE:%%{http_code}" -H "Authorization: Bearer %API_KEY%" %BASE_URL%/models') do (
    set "models_response=%%a"
)

for /f "tokens=2 delims=:" %%b in ("%models_response%") do (
    set "models_status=%%b"
)
set "models_body=%models_response:STATUS_CODE:%=%"

if "%models_status:~0,1%"=="2" (
    echo %GREEN%√ 通过%NC% (状态码: %models_status%)
    set /a TESTS_PASSED+=1
) else (
    echo %RED%× 失败%NC% (状态码: %models_status%)
    echo 响应: %models_body%
)
echo.

REM 测试7: 测试流式响应
echo %YELLOW%=== 测试7: 测试流式响应 ===%NC%
set /a TOTAL_TESTS+=1
echo %BLUE%测试: 流式聊天完成%NC%

for /f "tokens=*" %%a in ('curl -s -w "STATUS_CODE:%%{http_code}" -X POST -H "Authorization: Bearer %API_KEY%" -H "Content-Type: application/json" -d "{""model"":""gemini-1.5-flash"",""messages"":[{""role"":""user"",""content"":""Say hi""}],""max_tokens"":5,""stream"":true}" %BASE_URL%/chat/completions') do (
    set "stream_response=%%a"
)

for /f "tokens=2 delims=:" %%b in ("%stream_response%") do (
    set "stream_status=%%b"
)
set "stream_body=%stream_response:STATUS_CODE:%=%"

if "%stream_status:~0,1%"=="2" (
    echo %GREEN%√ 通过%NC% (状态码: %stream_status%)
    set /a TESTS_PASSED+=1
) else (
    echo %RED%× 失败%NC% (状态码: %stream_status%)
    echo 响应: %stream_body%
)
echo.

REM 测试结果总结
echo %BLUE%=== 测试结果总结 ===%NC%
echo 总测试数: %TOTAL_TESTS%
echo 通过: %GREEN%%TESTS_PASSED%%NC%
echo 失败: %RED%%TESTS_FAILED%%NC%

if %TESTS_FAILED%==0 (
    echo %GREEN%所有测试通过! √%NC%
    exit /b 0
) else (
    echo %RED%部分测试失败 ×%NC%
    exit /b 1
)