#!/bin/bash
# Nurova 2.0 — Backend Setup Script
# Run: chmod +x setup.sh && ./setup.sh

set -e

echo "🚀 Setting up Nurova 2.0 Backend..."

# Python venv
python3 -m venv venv
source venv/bin/activate

echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo "🤖 Training ML models (this takes ~30 seconds)..."
python train_models.py

echo "✅ Setup complete!"
echo ""
echo "To start the API:"
echo "  source venv/bin/activate"
echo "  python app.py"
echo ""
echo "API will run at: http://localhost:5000"
echo "Test with: curl http://localhost:5000/health"
