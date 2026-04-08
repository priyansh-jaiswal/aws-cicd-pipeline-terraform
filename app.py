from flask import Flask, jsonify
import datetime
import os

app = Flask(__name__)

# ── Routes ────────────────────────────────────────────────────────

@app.route('/')
def home():
    return jsonify({
        'message':     'AWS CI/CD Pipeline - Flask App',
        'status':      'running',
        'version':     '1.0.0',
        'deployed_by': 'AWS CodePipeline + ECS',
        'timestamp':   str(datetime.datetime.now())
    })

@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': str(datetime.datetime.now())
    }), 200

@app.route('/info')
def info():
    return jsonify({
        'app':         'E-Commerce API',
        'version':     '1.0.0',
        'environment': os.environ.get('ENV', 'production'),
        'region':      os.environ.get('AWS_REGION', 'ap-south-1'),
        'description': 'Deployed using AWS CI/CD Pipeline with Terraform'
    })

# ── Run ───────────────────────────────────────────────────────────
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
