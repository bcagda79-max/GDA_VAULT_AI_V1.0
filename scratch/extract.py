import json
import os

transcript_path = r'C:\Users\Mega Providers\.gemini\antigravity-ide\brain\a2f038c9-6291-482c-ac41-e8a16ef5f41c\.system_generated\logs\transcript.jsonl'
with open(transcript_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('type') == 'VIEW_FILE' and 'chat_screen.dart' in data.get('content', ''):
                content = data.get('content')
                if 'Showing lines 1 to 250' in content:
                    with open('scratch/chat_screen_1.txt', 'w', encoding='utf-8') as out:
                        out.write(content)
                elif 'Showing lines 250 to 480' in content:
                    with open('scratch/chat_screen_2.txt', 'w', encoding='utf-8') as out:
                        out.write(content)
        except Exception as e:
            pass
