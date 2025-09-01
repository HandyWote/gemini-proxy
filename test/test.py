import requests

headers = {
    'Authorization': 'Bearer AIzaSyAi4rV-M-TY9ezjGpZls9_mvr1ia4HJjcs',
    'Content-Type': 'application/json'
}

url = 'https://gemini-proxy.18666119673.workers.dev/chat/completions'
data = {
    'model': 'gemini-1.5-pro',
    'messages': [
        {'role': 'user', 'content': 'Hello, how are you?'}
    ]
}
response = requests.post(url, headers=headers, json=data)
# response = requests.get(url, headers=headers)

print(response.json())