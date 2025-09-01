#!/bin/bash

# Gemini代理项目测试脚本
# 适用于Windows Git Bash或WSL环境
# 用于测试Cloudflare Worker代理的Gemini API功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_BASE_URL="http://localhost:8787"
DEFAULT_API_KEY="your-gemini-api-key-here"

# 帮助信息
show_help() {
    echo "使用方法: $0 [选项]"
    echo
    echo "选项:"
    echo "  -u, --url URL        设置代理服务器URL (默认: $DEFAULT_BASE_URL)"
    echo "  -k, --key KEY        设置Gemini API密钥"
    echo "  -h, --help           显示此帮助信息"
    echo
    echo "示例:"
    echo "  $0 -k your-actual-api-key"
    echo "  $0 -u http://your-worker.your-subdomain.workers.dev -k your-api-key"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            BASE_URL="$2"
            shift 2
            ;;
        -k|--key)
            API_KEY="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 设置默认值
BASE_URL=${BASE_URL:-$DEFAULT_BASE_URL}
API_KEY=${API_KEY:-$DEFAULT_API_KEY}

# 检查是否提供了API密钥
if [ "$API_KEY" = "$DEFAULT_API_KEY" ]; then
    echo -e "${YELLOW}警告: 使用默认API密钥，请使用 -k 参数提供真实的API密钥${NC}"
fi

echo -e "${BLUE}=== Gemini代理测试脚本 ===${NC}"
echo -e "代理服务器: ${GREEN}$BASE_URL${NC}"
echo -e "测试时间: $(date)"
echo

# 测试计数器
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# 测试函数
run_test() {
    local test_name=$1
    local curl_command=$2
    local expected_status=$3
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -e "${BLUE}测试: $test_name${NC}"
    
    # 执行curl命令并捕获响应
    response=$(eval "$curl_command" 2>/dev/null)
    status_code=$(eval "$curl_command -w '%{http_code}' -o /dev/null -s" 2>/dev/null)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✓ 通过${NC} (状态码: $status_code)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ 失败${NC} (期望: $expected_status, 实际: $status_code)"
        echo "响应: $response"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo
}

# 测试1: CORS预检请求
echo -e "${YELLOW}=== 测试1: CORS预检请求 ===${NC}"
run_test "OPTIONS请求" "curl -s -X OPTIONS $BASE_URL" "200"

# 测试2: 无认证头的请求
echo -e "${YELLOW}=== 测试2: 无认证头请求 ===${NC}"
run_test "无认证头" "curl -s $BASE_URL" "401"

# 测试3: 无效的认证格式
echo -e "${YELLOW}=== 测试3: 无效认证格式 ===${NC}"
run_test "无效认证格式" "curl -s -H 'Authorization: InvalidFormat' $BASE_URL" "401"

# 测试4: 有效的认证头但无效的API密钥
echo -e "${YELLOW}=== 测试4: 有效格式但无效密钥 ===${NC}"
run_test "有效格式无效密钥" "curl -s -H 'Authorization: Bearer invalid-key' $BASE_URL" "401"

# 测试5: 测试/chat/completions端点（需要有效API密钥）
echo -e "${YELLOW}=== 测试5: 测试聊天完成端点 ===${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}测试: 聊天完成端点${NC}"

chat_response=$(curl -s -w '\n%{http_code}' -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gemini-1.5-flash",
        "messages": [{"role": "user", "content": "Hello"}],
        "max_tokens": 10
    }' \
    "$BASE_URL/chat/completions")

chat_status=$(echo "$chat_response" | tail -n1)
chat_body=$(echo "$chat_response" | sed '$d')

if [[ "$chat_status" =~ ^[2-4][0-9][0-9]$ ]]; then
    echo -e "${GREEN}✓ 通过${NC} (状态码: $chat_status)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ 失败${NC} (状态码: $chat_status)"
    echo "响应: $chat_body"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo

# 测试6: 测试/models端点
echo -e "${YELLOW}=== 测试6: 测试模型列表端点 ===${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}测试: 模型列表端点${NC}"

models_response=$(curl -s -w '\n%{http_code}' \
    -H "Authorization: Bearer $API_KEY" \
    "$BASE_URL/models")

models_status=$(echo "$models_response" | tail -n1)
models_body=$(echo "$models_response" | sed '$d')

if [[ "$models_status" =~ ^[2-4][0-9][0-9]$ ]]; then
    echo -e "${GREEN}✓ 通过${NC} (状态码: $models_status)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ 失败${NC} (状态码: $models_status)"
    echo "响应: $models_body"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo

# 测试7: 测试流式响应
echo -e "${YELLOW}=== 测试7: 测试流式响应 ===${NC}"
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo -e "${BLUE}测试: 流式聊天完成${NC}"

stream_response=$(curl -s -w '\n%{http_code}' -X POST \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
        "model": "gemini-1.5-flash",
        "messages": [{"role": "user", "content": "Say hi"}],
        "max_tokens": 5,
        "stream": true
    }' \
    "$BASE_URL/chat/completions")

stream_status=$(echo "$stream_response" | tail -n1)
stream_body=$(echo "$stream_response" | sed '$d')

if [[ "$stream_status" =~ ^[2-4][0-9][0-9]$ ]]; then
    echo -e "${GREEN}✓ 通过${NC} (状态码: $stream_status)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ 失败${NC} (状态码: $stream_status)"
    echo "响应: $stream_body"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo

# 测试结果总结
echo -e "${BLUE}=== 测试结果总结 ===${NC}"
echo -e "总测试数: ${TOTAL_TESTS}"
echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}所有测试通过! ✓${NC}"
    exit 0
else
    echo -e "${RED}部分测试失败 ✗${NC}"
    exit 1
fi