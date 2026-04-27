from fastapi import FastAPI

app = FastAPI(title="Gemma Local API")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
