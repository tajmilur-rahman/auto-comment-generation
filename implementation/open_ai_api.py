import openai
import time
import json
import chardet
import os

output_file = "d_issues_with_conversation_summary.json"

# Load OpenAI API key from a separate file (not tracked by git)
def load_openai_api_key():
    key_path = os.path.join(os.path.dirname(__file__), 'openai_key.py')
    if not os.path.exists(key_path):
        raise FileNotFoundError(f"API key file not found: {key_path}\nPlease create a file named 'openai_key.py' in the implementation folder with a line: OPENAI_API_KEY = 'your-key-here'")
    namespace = {}
    with open(key_path, 'r', encoding='utf-8') as f:
        exec(f.read(), namespace)
    return namespace['OPENAI_API_KEY']

openai.api_key = load_openai_api_key()

# system commands
system_commands = """
Each time user will gave you a workflow process code, Your task is to
generate single-line comments to explain what each section of the code does.
code section means 'input', 'output', 'script', 'when', 'stub', 'container', etc.

Comments should starts with // for Groovy and hash for Bash. 
Your task is to add single-line comments and not alter the existing code.
Also add one line comment at the very beginning of the code block to explain what the code does in general.

user may say 'here is the workflow process code now generate the single line comments',
but in response you should always only return the exact code with your comments. no extra text like
"Sure, here is the code with comments" or "Here is the code with comments added".

Do not add any extra text, characters or programming language type.
you can insert multiple single-line comments for a single code block.

#1 example:
input will be:
"process exampleProcess1 {

    input:
    some code...
        
    output:
    some code...
        
}"

your output should be:
"// this process does ...
 process exampleProcess1 {
 
 // this section does ...
 input:
 some code...
 
 // this section does ...
 output:
 some code...
 
}"
"""

prompt_before = """
here is the workflow process code:
"""

prompt_after = """
Please generate single-line comments to explain what each section of the code does.
"""

# Define a function to call the GPT-4 API
def generate_response(prompt):
    response = openai.ChatCompletion.create(
        #model="gpt-4",  # Specify the model you want to use
        model="gpt-4o-mini",  # Specify the model you want to use

        messages=[
            {"role": "system", "content": system_commands},
            {"role": "user", "content": prompt_before + prompt + prompt_after}  # The user's message
        ],
        temperature=0.7,  # Adjusts the randomness of the output
    )
    return response['choices'][0]['message']['content']