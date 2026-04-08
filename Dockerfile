# ── Base image ───────────────────────────────────────────────────
FROM python:3.12-slim

# ── Set working directory ─────────────────────────────────────────
WORKDIR /app

# ── Install dependencies ──────────────────────────────────────────
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ── Copy app code ─────────────────────────────────────────────────
COPY app.py .

# ── Expose port ───────────────────────────────────────────────────
EXPOSE 5000

# ── Run with gunicorn (production server) ─────────────────────────
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
