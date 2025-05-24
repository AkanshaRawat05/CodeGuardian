from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import subprocess
import json

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = "backend/uploads"
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
@app.route("/upload", methods=["POST"])
def upload_file():
    file = request.files.get("file")
    if not file:
        print("No file part in request")
        return jsonify({"error": "No file part"}), 400

    filename = file.filename
    if filename == "":
        print("No selected file")
        return jsonify({"error": "No selected file"}), 400

    upload_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(upload_path)
    print(f"[✓] File saved to: {upload_path}")

    try:
        abs_path = os.path.abspath(upload_path)
        print(f"[→] Running: bash run_all.sh {abs_path}")
        result = subprocess.run(
            ["bash", "run_all.sh", abs_path],
            cwd="/home/akansharawat/security_compiler",  # absolute path
            capture_output=True,
            text=True,
            timeout=30
        )

        print("----- STDOUT -----")
        print(result.stdout)
        print("----- STDERR -----")
        print(result.stderr)

        if result.returncode != 0:
            print("[✗] run_all.sh failed")
            return jsonify({"error": "Analysis failed", "details": result.stderr}), 500
        else:
            print("[✓] run_all.sh succeeded")

    except subprocess.TimeoutExpired:
        print("[✗] run_all.sh timed out")
        return jsonify({"error": "Analysis timeout"}), 500

    #analysis_json_path = os.path.join("backend", "analysis.json")
    analysis_json_path = "analysis.json"  # If it's saved in project root

    print(f"[→] Looking for: {analysis_json_path}")

    if not os.path.exists(analysis_json_path):
        print("[✗] analysis.json not found")
        return jsonify({"error": "analysis.json not found after analysis"}), 500

    try:
        with open(analysis_json_path, "r") as f:
            data = json.load(f)
        print("[✓] Loaded analysis.json successfully")
        return jsonify(data)
    except Exception as e:
        print("[✗] Failed to parse analysis.json")
        return jsonify({"error": "Failed to parse analysis.json", "details": str(e)}), 500

if __name__ == "__main__":
    print("🚀 Starting Flask server...")
    app.run(debug=True)
