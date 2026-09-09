from flask import Flask, request, send_file, jsonify
from flask_cors import CORS
from deep_translator import GoogleTranslator
from indic_transliteration import sanscript
from indic_transliteration.sanscript import transliterate
import edge_tts
import asyncio, os, uuid

app = Flask(__name__)
CORS(app)

VOICES = {
    "male": "ta-IN-ValluvarNeural",
    "female": "ta-IN-PallaviNeural"
}

def thanglish_to_tamil(text):
    # ITRANS is the closest standard scheme to casual Thanglish typing
    return transliterate(text, sanscript.ITRANS, sanscript.TAMIL)

def tamil_to_thanglish(text):
    return transliterate(text, sanscript.TAMIL, sanscript.ITRANS)

async def generate_speech(tamil_text, voice_key, out_path):
    voice = VOICES.get(voice_key, VOICES["female"])
    communicate = edge_tts.Communicate(tamil_text, voice)
    await communicate.save(out_path)

@app.route("/process", methods=["POST"])
def process():
    data = request.json
    input_type = data.get("input_type")   # "thanglish" or "english"
    text = data.get("text", "").strip()
    voice = data.get("voice", "female")   # "male" or "female"

    if not text:
        return jsonify({"error": "No text provided"}), 400

    if input_type == "thanglish":
        tamil_text = thanglish_to_tamil(text)
        other_text = GoogleTranslator(source="ta", target="en").translate(tamil_text)
    else:  # english
        tamil_text = GoogleTranslator(source="en", target="ta").translate(text)
        other_text = tamil_to_thanglish(tamil_text)

    filename = f"{uuid.uuid4()}.mp3"
    out_path = os.path.join("audio", filename)
    os.makedirs("audio", exist_ok=True)
    asyncio.run(generate_speech(tamil_text, voice, out_path))

    return jsonify({
        "tamil_text": tamil_text,
        "translated_text": other_text,
        "audio_url": f"/audio/{filename}"
    })

@app.route("/audio/<filename>")
def get_audio(filename):
    return send_file(os.path.join("audio", filename), mimetype="audio/mpeg")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
