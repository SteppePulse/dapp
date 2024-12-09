import os
import telebot
import threading
import schedule
import time
from flask import Flask, request
from telebot.types import InlineKeyboardMarkup, InlineKeyboardButton
import requests
import json
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Bot Configuration and Environment Variables
BOT_TOKEN = os.getenv('TELEGRAM_BOT_TOKEN')
ADMIN_CHAT_ID = os.getenv('ADMIN_CHAT_ID')

# Initialize Flask and Telebot
app = Flask(__name__)
bot = telebot.TeleBot(BOT_TOKEN)

# Project Context Data (from the provided snippet)
TEAM_MEMBERS = [
    {
        "name": 'Henry Kimani',
        "role": 'CEO & co-founder',
        "description": 'Software Engineer.'
    },
    {
        "name": 'Bridgit Nyambeka',
        "role": 'Project Manager & co-founder',
        "description": 'Software Engineer & Graphic Designer'
    },
    {
        "name": 'Mirriam Njeri',
        "role": 'Marketing, Community lead & co-founder',
        "description": 'Journalist & software developer.'
    },
    {
        "name": 'Brandistone Nyabonyi',
        "role": 'CTO & co-founder',
        "description": 'Software Engineer'
    }
]

ECOSYSTEMS = [
    {
        "title": 'Marine Conservation',
        "description": 'Protecting ocean biodiversity through blockchain-powered initiatives'
    },
    {
        "title": 'Forest Preservation',
        "description": 'Securing critical forest habitats and supporting reforestation efforts'
    },
    {
        "title": 'Alpine Ecosystem',
        "description": 'Safeguarding high-altitude wildlife and fragile mountain environments'
    },
    {
        "title": 'Migratory Pathways',
        "description": 'Tracking and protecting critical migration routes for endangered species'
    }
]

FAQS = [
    {
        "question": "What is our primary mission?",
        "answer": "We aim to leverage blockchain technology to support wildlife conservation efforts, creating unique digital assets that directly contribute to ecosystem preservation."
    },
    {
        "question": "How do NFTs support conservation?",
        "answer": "Each NFT represents a direct contribution to wildlife protection, with proceeds funding conservation projects, research, and habitat preservation."
    },
    {
        "question": "Can anyone join the community?",
        "answer": "Absolutely! We welcome anyone passionate about wildlife conservation and innovative blockchain solutions to join our global community."
    },
    {
        "question": "How are funds used?",
        "answer": "Funds are carefully allocated to vetted conservation projects, scientific research, and community-driven initiatives that protect endangered ecosystems."
    }
]

# Intelligent Conversation Handler
class ConversationHandler:
    def __init__(self):
        self.conversation_state = {}
    
    def process_message(self, chat_id, message):
        """
        Intelligent message processing with context-aware responses
        """
        message_lower = message.lower()
        
        # Mission and Project Queries
        if any(keyword in message_lower for keyword in ['mission', 'goal', 'purpose']):
            return """🌍 Steppe Pulse Mission:
We're pioneering a revolutionary intersection of blockchain technology and wildlife conservation. 
Our mission is to transform digital assets into powerful conservation tools, connecting passionate global citizens with critical environmental challenges."""
        
        # Team Queries
        if any(keyword in message_lower for keyword in ['team', 'founder', 'members']):
            team_info = "🤝 Our Founding Team:\n\n"
            for member in TEAM_MEMBERS:
                team_info += f"*{member['name']}* - {member['role']}\n{member['description']}\n\n"
            return team_info
        
        # Ecosystem Queries
        if any(keyword in message_lower for keyword in ['ecosystem', 'conservation', 'project']):
            ecosystem_info = "🌱 Our Conservation Ecosystems:\n\n"
            for ecosystem in ECOSYSTEMS:
                ecosystem_info += f"*{ecosystem['title']}*\n{ecosystem['description']}\n\n"
            return ecosystem_info
        
        # FAQ Handling
        if any(keyword in message_lower for keyword in ['help', 'question', 'faq']):
            faq_info = "❓ Frequently Asked Questions:\n\n"
            for faq in FAQS:
                faq_info += f"*Q: {faq['question']}*\nA: {faq['answer']}\n\n"
            return faq_info
        
        # Generic Fallback
        return """🤖 I'm an intelligent bot for Steppe Pulse Wildlife Conservation. 
I can help you with information about our mission, team, ecosystems, and NFT projects. 
Try asking about our mission, team, ecosystems, or frequently asked questions!"""

# Initialize Conversation Handler
conversation_handler = ConversationHandler()

# Scheduled Daily Messages
def send_daily_conservation_update():
    """
    Send daily conservation updates to subscribed users
    """
    updates = [
        "🐘 Did you know? African elephants are keystone species crucial for maintaining ecosystem balance.",
        "🌍 Every NFT purchased helps protect critical wildlife habitats around the globe!",
        "🌱 Reforestation update: Our latest project has planted 1000 trees in critical forest zones.",
        "🐝 Biodiversity matters: Pollinators like bees are essential for global food security."
    ]
    
    # In a real implementation, you'd have a list of subscribed chat IDs
    # For demonstration, we're using the admin chat ID
    bot.send_message(ADMIN_CHAT_ID, updates[int(time.time()) % len(updates)])

# Scheduled Update Thread
def run_scheduler():
    schedule.every().day.at("09:00").do(send_daily_conservation_update)
    while True:
        schedule.run_pending()
        time.sleep(1)

# Telegram Bot Event Handlers
@bot.message_handler(commands=['start'])
def send_welcome(message):
    """Welcome message and bot introduction"""
    welcome_text = """🌍 Welcome to Steppe Pulse Conservation Bot! 

I'm your intelligent assistant for wildlife conservation and blockchain innovation. 
What would you like to know about our mission, team, or conservation efforts?

Quick Commands:
/mission - Learn about our vision
/team - Meet our founders
/ecosystems - Explore our conservation focus areas
/faq - Frequently Asked Questions"""
    
    markup = InlineKeyboardMarkup()
    mission_btn = InlineKeyboardButton("Our Mission", callback_data="mission")
    team_btn = InlineKeyboardButton("Our Team", callback_data="team")
    ecosystems_btn = InlineKeyboardButton("Ecosystems", callback_data="ecosystems")
    
    markup.row(mission_btn, team_btn, ecosystems_btn)
    
    bot.reply_to(message, welcome_text, reply_markup=markup)

@bot.message_handler(func=lambda message: True)
def handle_message(message):
    """Intelligent message handler"""
    response = conversation_handler.process_message(message.chat.id, message.text)
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.callback_query_handler(func=lambda call: True)
def callback_query(call):
    """Handle inline keyboard callbacks"""
    if call.data == "mission":
        bot.answer_callback_query(call.id, "Our Mission")
        bot.send_message(call.message.chat.id, FAQS[0]['answer'], parse_mode='Markdown')
    elif call.data == "team":
        bot.answer_callback_query(call.id, "Our Team")
        team_info = "🤝 Our Founding Team:\n\n"
        for member in TEAM_MEMBERS:
            team_info += f"*{member['name']}* - {member['role']}\n{member['description']}\n\n"
        bot.send_message(call.message.chat.id, team_info, parse_mode='Markdown')
    elif call.data == "ecosystems":
        bot.answer_callback_query(call.id, "Conservation Ecosystems")
        ecosystem_info = "🌱 Our Conservation Ecosystems:\n\n"
        for ecosystem in ECOSYSTEMS:
            ecosystem_info += f"*{ecosystem['title']}*\n{ecosystem['description']}\n\n"
        bot.send_message(call.message.chat.id, ecosystem_info, parse_mode='Markdown')

# Flask Webhook Routes
@app.route('/' + BOT_TOKEN, methods=['POST'])
def webhook():
    """Webhook endpoint for receiving Telegram updates"""
    json_string = request.get_data().decode('utf-8')
    update = telebot.types.Update.de_json(json_string)
    bot.process_new_updates([update])
    return "OK", 200

@app.route('/')
def index():
    """Basic health check route"""
    return "Steppe Pulse Conservation Bot is running!", 200

# Main Execution
def start_bot():
    
    # Start scheduled updates in a separate thread
    scheduler_thread = threading.Thread(target=run_scheduler)
    scheduler_thread.start()

if __name__ == '__main__':
    start_bot()
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))