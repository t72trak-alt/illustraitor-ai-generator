# backend/api_server.py - Illustraitor AI API с поддержкой DALL-E 3 и Unsplash
import os
import requests
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Literal
import openai
import aiohttp
from datetime import datetime
from dotenv import load_dotenv
# Загрузка переменных окружения
load_dotenv()
# Инициализация FastAPI
app = FastAPI(
    title="Illustraitor AI API",
    description="API для генерации изображений через DALL-E 3 и поиска через Unsplash",
    version="2.0.0"
)
# Настройка CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Для разработки
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# Модели запросов
class ImageRequest(BaseModel):
    prompt: str
    style: Optional[str] = None
    api_key: str  # Основной ключ
    source: Literal["openai", "unsplash"] = "openai"
    unsplash_key: Optional[str] = None  # Дополнительный ключ Unsplash
    size: str = "1024x1024"
    quality: str = "standard"
    color: Optional[str] = None
    orientation: Optional[str] = None
# ==================== DALL-E 3 ====================
async def generate_with_dalle(prompt: str, api_key: str, size: str = "1024x1024", quality: str = "standard") -> dict:
    """Генерация через DALL-E 3"""
    try:
        client = openai.OpenAI(api_key=api_key)
        response = client.images.generate(
            model="dall-e-3",
            prompt=prompt,
            size=size,
            quality=quality,
            n=1,
            response_format="url"
        )
        return {
            "image_url": response.data[0].url,
            "revised_prompt": response.data[0].revised_prompt,
            "model": "dall-e-3"
        }
    except openai.AuthenticationError:
        raise HTTPException(status_code=401, detail="Неверный API ключ OpenAI")
    except openai.RateLimitError:
        raise HTTPException(status_code=429, detail="Превышен лимит запросов")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка DALL-E: {str(e)}")
# ==================== UNSPLASH ====================
async def search_unsplash(query: str, api_key: str, color: Optional[str] = None, 
                         orientation: Optional[str] = None) -> dict:
    """Поиск через Unsplash API"""
    try:
        url = "https://api.unsplash.com/search/photos"
        headers = {
            "Authorization": f"Client-ID {api_key}",
            "Accept-Version": "v1"
        }
        params = {
            "query": query,
            "per_page": 1,
            "page": 1
        }
        if color:
            params["color"] = color
        if orientation:
            params["orientation"] = orientation
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers=headers, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    if data["results"]:
                        photo = data["results"][0]
                        return {
                            "image_url": photo["urls"]["regular"],
                            "description": photo.get("description", query),
                            "photographer": photo["user"]["name"],
                            "photographer_url": photo["user"]["links"]["html"],
                            "unsplash_url": photo["links"]["html"],
                            "color": photo.get("color"),
                            "source": "unsplash"
                        }
                    else:
                        raise HTTPException(status_code=404, detail="Изображения не найдены")
                elif response.status == 401:
                    raise HTTPException(status_code=401, detail="Неверный Unsplash Access Key")
                else:
                    error_text = await response.text()
                    raise HTTPException(status_code=response.status, detail=f"Ошибка Unsplash: {error_text}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка поиска: {str(e)}")
# ==================== ОСНОВНОЙ ЭНДПОИНТ ====================
@app.post("/generate")
async def generate_image(request: ImageRequest):
    """Генерация/поиск изображений"""
    print(f"[{datetime.now()}] Запрос: source={request.source}, prompt={request.prompt[:50]}...")
    try:
        if request.source == "openai":
            # Генерация через DALL-E 3
            result = await generate_with_dalle(
                prompt=request.prompt,
                api_key=request.api_key,
                size=request.size,
                quality=request.quality
            )
            return {
                "success": True,
                "image_url": result["image_url"],
                "revised_prompt": result.get("revised_prompt", request.prompt),
                "prompt": request.prompt,
                "style": request.style,
                "source": "dall-e-3",
                "timestamp": datetime.now().isoformat()
            }
        elif request.source == "unsplash":
            # Поиск через Unsplash
            unsplash_api_key = request.unsplash_key or request.api_key
            result = await search_unsplash(
                query=request.prompt,
                api_key=unsplash_api_key,
                color=request.color,
                orientation=request.orientation
            )
            return {
                "success": True,
                "image_url": result["image_url"],
                "prompt": request.prompt,
                "description": result.get("description", request.prompt),
                "photographer": result.get("photographer"),
                "photographer_url": result.get("photographer_url"),
                "unsplash_url": result.get("unsplash_url"),
                "source": "unsplash",
                "timestamp": datetime.now().isoformat()
            }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка сервера: {str(e)}")
# ==================== ДОПОЛНИТЕЛЬНЫЕ ЭНДПОИНТЫ ====================
@app.get("/health")
async def health_check():
    """Проверка здоровья сервера"""
    return {
        "status": "healthy",
        "service": "Illustraitor AI API",
        "version": "2.0.0",
        "timestamp": datetime.now().isoformat(),
        "features": ["dall-e-3", "unsplash"]
    }
@app.post("/validate/openai")
async def validate_openai_key(api_key: str):
    """Валидация OpenAI API ключа"""
    try:
        client = openai.OpenAI(api_key=api_key)
        client.models.list(limit=1)
        return {"valid": True, "message": "OpenAI API ключ действителен"}
    except Exception as e:
        return {"valid": False, "message": str(e)}
@app.post("/validate/unsplash")
async def validate_unsplash_key(api_key: str):
    """Валидация Unsplash API ключа"""
    try:
        url = "https://api.unsplash.com/photos/random"
        headers = {"Authorization": f"Client-ID {api_key}"}
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers=headers) as response:
                if response.status == 200:
                    return {"valid": True, "message": "Unsplash Access Key действителен"}
                else:
                    return {"valid": False, "message": f"Код ошибки: {response.status}"}
    except Exception as e:
        return {"valid": False, "message": str(e)}
@app.get("/")
async def root():
    """Информация о API"""
    return {
        "message": "Illustraitor AI API",
        "version": "2.0.0",
        "endpoints": {
            "POST /generate": "Генерация/поиск изображений",
            "GET /health": "Проверка здоровья",
            "POST /validate/openai": "Валидация OpenAI ключа",
            "POST /validate/unsplash": "Валидация Unsplash ключа"
        },
        "sources": ["DALL-E 3 (генерация)", "Unsplash (поиск)"]
    }
if __name__ == "__main__":
    import uvicorn
    print("🚀 Illustraitor AI API запущен")
    print("📚 Документация: http://localhost:8000/docs")
    print("🔧 Источники: DALL-E 3 и Unsplash")
    uvicorn.run(app, host="0.0.0.0", port=8000, log_level="info")
