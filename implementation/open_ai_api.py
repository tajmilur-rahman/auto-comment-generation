import openai
import time
import json
import chardet

output_file = "d_issues_with_conversation_summary.json"

# Set your API key
openai.api_key = "enter your openai api key here"

# system commands
system_commands = """
Each time user will gave you a workflow process code, Your task is to
generate single-line comments to explain what each section of the code does.
code section means 'input', 'output', 'script', 'when', 'stub', 'container', etc.
A single-line comment is typically used to explain or clarify a specific line of code. 
It starts with // for Groovy and hash for Bash. 
Your task is to add single-line comments and not alter the existing code.
Also add one line comment at the very beginning of the code block to explain what the code does in general.

A sample input will be:
"process exampleProcess1 {\n\n    input:\n        some code...\n\n    output:\n        some code...\n\n    \n\n}"
and your output should be:
"// explain what the process does\n process exampleProcess1 {\n\n    // explain what the input section does \ninput:\n        some code...\n\n    // explalin what the output section does \noutput:\n        some code...\n\n    \n\n}"

Another sample input will be:
"process exampleProcess2 {\n\n    section1:\n        some code...\n\n    section2:\n        some code...\n\n    \n\n}"
and your corresponding output should be:
"// explain what the process does\n process exampleProcess2 {\n\n    // explain what the section1 does \nsection1:\n        some code...\n\n    // explalin what the section2 does \nsection2:\n        some code...\n\n    \n\n}"

user may say 'here is the workflow process code now generate the single line comments',
but in response you should always only return the exact code with your comments. no extra text like
"Sure, here is the code with comments" or "Here is the code with comments added".
Do not add any extra text or explanation outside the code block.
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
        max_tokens=500,  # Maximum number of tokens in the output
    )
    return response['choices'][0]['message']['content']