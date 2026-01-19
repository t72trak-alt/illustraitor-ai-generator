// Illustraitor AI - ФИНАЛЬНАЯ ИСПРАВЛЕННАЯ ВЕРСИЯ
console.log("🚀 Illustraitor AI loaded");
// ==================== КОНСТАНТЫ ====================
const STYLES = {
    "realistic": "фотореалистично, высокое качество, детализированно",
    "impressionism": "в стиле импрессионизм, мазки кистью",
    "surrealism": "сюрреализм, фантастическое",
    "abstract": "абстракционизм, геометрические формы",
    "pop-art": "поп-арт, яркие цвета",
    "cyberpunk": "киберпанк, неоновые огни",
    "steampunk": "стимпанк, викторианская эпоха",
    "fantasy": "фэнтези, волшебство",
    "anime": "аниме, японская анимация",
    "pixel-art": "пиксель-арт, 8-битная графика",
    "oil-painting": "картина маслом, масляные краски",
    "watercolor": "акварель, мягкие переходы",
    "black-white": "черно-белое, монохромное",
    "vintage": "винтаж, ретро",
    "cartoon": "мультяшный, анимационный"
};
const API_SERVER = "https://illustraitor-ai-generator.onrender.com";
// ==================== ХРАНЕНИЕ ====================
function saveAPIKeys() {
    const openaiKey = document.getElementById("openai-key").value.trim();
    const unsplashKey = document.getElementById("unsplash-key").value.trim();
    if (openaiKey || unsplashKey) {
        chrome.storage.local.set({ openaiKey, unsplashKey }, () => {
            console.log("💾 Ключи сохранены");
        });
    }
}
function loadAPIKeys() {
    chrome.storage.local.get(["openaiKey", "unsplashKey"], (result) => {
        const openaiInput = document.getElementById("openai-key");
        const unsplashInput = document.getElementById("unsplash-key");
        if (openaiInput && result.openaiKey) openaiInput.value = result.openaiKey;
        if (unsplashInput && result.unsplashKey) unsplashInput.value = result.unsplashKey;
        console.log("📂 Ключи загружены");
    });
}
// ==================== ПРОВЕРКА СЕРВЕРА ====================
async function checkServerHealth() {
    try {
        const response = await fetch(`${API_SERVER}/health`, { timeout: 5000 });
        return response.ok;
    } catch {
        return false;
    }
}
// ==================== ПРОВЕРКА КЛЮЧЕЙ ====================
async function validateOpenAIKey() {
    const input = document.getElementById("openai-key");
    const key = input?.value.trim();
    const status = document.getElementById("status-openai");
    if (!key) {
        alert("❌ Введите OpenAI ключ");
        return;
    }
    if (!key.startsWith("sk-")) {
        alert("❌ Ключ должен начинаться с 'sk-'");
        return;
    }
    if (status) {
        status.textContent = "🔍 Проверка ключа...";
        status.style.color = "#f9e2af";
    }
    // Сначала проверяем доступен ли сервер
    const serverAvailable = await checkServerHealth();
    if (!serverAvailable) {
        // Fallback: базовая проверка если сервер недоступен
        if (key.startsWith("sk-") && key.length > 20) {
            alert("⚠️ Сервер проверки недоступен\n✅ Ключ имеет правильный формат (sk-...)");
            if (status) {
                status.textContent = "⚠️ Сервер недоступен, формат OK";
                status.style.color = "#f9e2af";
            }
        } else {
            alert("⚠️ Сервер проверки недоступен\n❌ Проверьте формат ключа (sk-...)");
        }
        return;
    }
    try {
        const response = await fetch(`${API_SERVER}/validate/openai`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ api_key: key })
        });
        if (response.ok) {
            const data = await response.json();
            if (data.valid) {
                alert("✅ OpenAI ключ валиден!");
                if (status) {
                    status.textContent = "✅ Ключ валиден";
                    status.style.color = "#a6e3a1";
                }
        updateDownloadButton();
            } else {
                alert(`❌ Ключ невалиден: ${data.message || "Ошибка"}`);
            }
        } else {
            alert("❌ Ошибка сервера при проверке");
        }
    } catch (error) {
        console.error("Ошибка проверки:", error);
        alert("❌ Не удалось проверить ключ. Проверьте соединение.");
    }
}
async function validateUnsplashKey() {
    const input = document.getElementById("unsplash-key");
    const key = input?.value.trim();
    const status = document.getElementById("status-unsplash");
    if (!key) {
        alert("❌ Введите Unsplash ключ");
        return;
    }
    if (key.length < 10) {
        alert("❌ Ключ должен быть не менее 10 символов");
        return;
    }
    if (status) {
        status.textContent = "🔍 Проверка ключа...";
        status.style.color = "#f9e2af";
    }
    // Сначала проверяем доступен ли сервер
    const serverAvailable = await checkServerHealth();
    if (!serverAvailable) {
        // Fallback: базовая проверка
        if (key.length >= 10) {
            alert("⚠️ Сервер проверки недоступен\n✅ Ключ имеет достаточную длину");
            if (status) {
                status.textContent = "⚠️ Сервер недоступен, длина OK";
                status.style.color = "#f9e2af";
            }
        }
        return;
    }
    try {
        const response = await fetch(`${API_SERVER}/validate/unsplash`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ api_key: key })
        });
        if (response.ok) {
            const data = await response.json();
            if (data.valid) {
                alert("✅ Unsplash ключ валиден!");
                if (status) {
                    status.textContent = "✅ Ключ валиден";
                    status.style.color = "#a6e3a1";
                }
        updateDownloadButton();
            } else {
                alert(`❌ Ключ невалиден: ${data.message || "Ошибка"}`);
            }
        } else {
            alert("❌ Ошибка сервера при проверке");
        }
    } catch (error) {
        console.error("Ошибка проверки:", error);
        alert("❌ Не удалось проверить ключ. Проверьте соединение.");
    }
}
// ==================== OPENAI ГЕНЕРАЦИЯ ====================
async function generateOpenAIImage() {
    console.log("🎨 Генерация OpenAI...");
    const apiKey = document.getElementById("openai-key").value.trim();
    const prompt = document.getElementById("openai-prompt").value.trim();
    const style = document.getElementById("openai-style").value;
    const status = document.getElementById("status-openai");
    const resultContainer = document.getElementById("result-container");
    // Проверка
    if (!apiKey) {
        alert("❌ Введите OpenAI ключ");
        return;
    }
    if (!prompt) {
        alert("❌ Введите описание изображения");
        return;
    }
    if (!apiKey.startsWith("sk-")) {
        alert("❌ Ключ должен начинаться с 'sk-'");
        return;
    }
    // Обновляем статус
    if (status) {
        status.textContent = "🔄 Генерация изображения...";
        status.style.color = "#f9e2af";
    }
    // Формируем запрос с исправленным quality
    const enhancedPrompt = `${prompt}, ${STYLES[style] || STYLES.realistic}`;
    try {
        const response = await fetch("https://api.openai.com/v1/images/generations", {
            method: "POST",
            headers: {
                "Authorization": `Bearer ${apiKey}`,
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                model: "gpt-image-1",
                prompt: enhancedPrompt,
                size: "1024x1024",
                quality: "auto",  // ИСПРАВЛЕНО: было "standard", теперь "auto" или "high"
                n: 1
            })
        });
        const data = await response.json();
        if (!response.ok) {
            // Детальная обработка ошибок
            let errorMsg = "Неизвестная ошибка";
            if (data.error) {
                errorMsg = data.error.message || data.error.code || "Ошибка OpenAI";
                // Специальная обработка для quality ошибки
                if (errorMsg.includes("quality") || errorMsg.includes("standart")) {
                    errorMsg = "Ошибка параметра quality. Используйте 'auto', 'low', 'medium', или 'high'.";
                }
            } else if (response.status === 401) {
                errorMsg = "Ошибка 401: Неверный API ключ. Проверьте:\n1. Ключ начинается с 'sk-'\n2. На аккаунте есть баланс\n3. Ключ не отозван";
            } else if (response.status === 429) {
                errorMsg = "Ошибка 429: Превышен лимит запросов. Подождите 1 минуту.";
            } else {
                errorMsg = `Ошибка ${response.status}: ${response.statusText}`;
            }
            throw new Error(errorMsg);
        }
        console.log("✅ Изображение создано:", data);
        // Показываем результат
        if (resultContainer) {
            resultContainer.innerHTML = `
                <div class="panel" style="margin-top:15px;">
                    <h3><i class="fas fa-image"></i> Изображение готово!</h3>
                    <img src="${data.data[0].url}" 
                         style="width:100%; border-radius:8px; margin:10px 0; border:2px solid #a6e3a1;">
                    <p style="color:#cdd6f4; margin:10px 0; font-size:12px;">
                        📏 Размер: 1024×1024<br>
                        🎨 Стиль: ${document.getElementById("openai-style").options[document.getElementById("openai-style").selectedIndex].text}
                    </p>
                    <div class="button-group">
                        <button onclick="downloadImage(data.data[0].url)" style="background:#89b4fa; color:#1e1e2e; border:none; padding:8px 15px; border-radius:5px; cursor:pointer; margin-left:10px;"><i class="fas fa-download"></i> Скачать</button><button onclick="window.open('${data.data[0].url}', '_blank')" 
                                style="background:#a6e3a1; color:#1e1e2e; border:none; padding:8px 15px; border-radius:5px; cursor:pointer; margin-right:10px;">
                            <i class="fas fa-external-link-alt"></i> Открыть
                        </button>
                        <button onclick="this.parentElement.parentElement.remove()" 
                                style="background:#f38ba8; color:#1e1e2e; border:none; padding:8px 15px; border-radius:5px; cursor:pointer;">
                            <i class="fas fa-times"></i> Закрыть
                        </button>
                    </div>
                </div>
            `;
        }
        if (status) {
            status.textContent = "✅ Изображение готово!";
            status.style.color = "#a6e3a1";
        }
        updateDownloadButton();
    } catch (error) {
        console.error("❌ Ошибка генерации:", error);
        if (status) {
            status.textContent = `❌ Ошибка`;
            status.style.color = "#f38ba8";
        }
        alert(`❌ Ошибка генерации:\n${error.message}`);
    }
}
// ==================== UNSPLASH ПОИСК ====================
async function searchUnsplash() {
    const apiKey = document.getElementById("unsplash-key").value.trim();
    const query = document.getElementById("unsplash-query").value.trim();
    const color = document.getElementById("unsplash-color").value;
    const status = document.getElementById("status-unsplash");
    if (!apiKey) {
        alert("❌ Введите Unsplash ключ");
        return;
    }
    if (!query) {
        alert("❌ Введите поисковый запрос");
        return;
    }
    if (status) {
        status.textContent = "🔍 Поиск фотографий...";
        status.style.color = "#f9e2af";
    }
    try {
        // Формируем URL запроса
        let url = `https://api.unsplash.com/search/photos?query=${encodeURIComponent(query)}&per_page=5`;
        if (color) {
            url += `&color=${color}`;
        }
        const response = await fetch(url, {
            headers: {
                "Authorization": `Client-ID ${apiKey}`,
                "Accept-Version": "v1"
            }
        });
        if (response.ok) {
            const data = await response.json();
            if (data.total > 0) {
                alert(`✅ Найдено ${data.total} фотографий\nПоказано: ${data.results.length} фото`);
                if (status) {
                    status.textContent = `✅ Найдено: ${data.total} фото`;
                    status.style.color = "#a6e3a1";
                }
        updateDownloadButton();
                // Можно добавить отображение превью
                console.log("Unsplash результаты:", data.results);
            } else {
                alert("❌ По запросу ничего не найдено");
                if (status) {
                    status.textContent = "❌ Ничего не найдено";
                    status.style.color = "#f38ba8";
                }
            }
        } else {
            const errorData = await response.json();
            throw new Error(errorData.errors?.[0] || `Ошибка Unsplash: ${response.status}`);
        }
    } catch (error) {
        console.error("Ошибка Unsplash:", error);
        // Fallback для тестирования
        alert(`🔍 Unsplash поиск:\n${error.message}\n\n(Для реального поиска нужен валидный ключ Unsplash)`);
        if (status) {
            status.textContent = "⚠️ Ошибка запроса";
            status.style.color = "#f9e2af";
        }
    }
}
// ==================== ИНИЦИАЛИЗАЦИЯ ====================
document.addEventListener("DOMContentLoaded", function() {
    console.log("📄 DOM загружен");
    // 1. Загружаем ключи
    loadAPIKeys();
    // 2. Элементы
    const openaiInput = document.getElementById("openai-key");
    const unsplashInput = document.getElementById("unsplash-key");
    // 3. Автосохранение при изменении
    if (openaiInput) openaiInput.addEventListener("input", saveAPIKeys);
    if (unsplashInput) unsplashInput.addEventListener("input", saveAPIKeys);
    // 4. Кнопки OpenAI
    document.getElementById("generate-openai")?.addEventListener("click", generateOpenAIImage);
    document.getElementById("save-openai")?.addEventListener("click", () => {
        if (openaiInput?.value.trim()) {
            saveAPIKeys();
            alert("✅ OpenAI ключ сохранен");
        } else {
            alert("⚠️ Введите ключ для сохранения");
        }
    });
    document.getElementById("delete-openai")?.addEventListener("click", () => {
        if (openaiInput) {
            openaiInput.value = "";
            saveAPIKeys();
            alert("🗑️ OpenAI ключ удален");
        }
    });
    document.getElementById("validate-openai")?.addEventListener("click", validateOpenAIKey);
    // 5. Кнопки Unsplash
    document.getElementById("search-unsplash")?.addEventListener("click", searchUnsplash);
    document.getElementById("save-unsplash")?.addEventListener("click", () => {
        if (unsplashInput?.value.trim()) {
            saveAPIKeys();
            alert("✅ Unsplash ключ сохранен");
        } else {
            alert("⚠️ Введите ключ для сохранения");
        }
    });
    document.getElementById("delete-unsplash")?.addEventListener("click", () => {
        if (unsplashInput) {
            unsplashInput.value = "";
            saveAPIKeys();
            alert("🗑️ Unsplash ключ удален");
        }
    });
    document.getElementById("validate-unsplash")?.addEventListener("click", validateUnsplashKey);
    // 6. Проверяем сервер и обновляем статус
    setTimeout(async () => {
        const globalStatus = document.getElementById("global-status");
        if (globalStatus) {
            const serverAvailable = await checkServerHealth();
            if (serverAvailable) {
                globalStatus.innerHTML = `<button onclick="downloadAPIKeys()" style="background:#89b4fa; color:#1e1e2e; border:none; padding:10px 20px; border-radius:6px; cursor:pointer; font-weight:bold; width:100%; margin-top:10px;"><i class="fas fa-download"></i> Скачать</button>`;
                globalStatus.style.color = "#a6e3a1";
            }
        updateDownloadButton(); else {
                globalStatus.innerHTML = `<button onclick="downloadAPIKeys()" style="background:#89b4fa; color:#1e1e2e; border:none; padding:10px 20px; border-radius:6px; cursor:pointer; font-weight:bold; width:100%; margin-top:10px;"><i class="fas fa-download"></i> Скачать</button>`;
                globalStatus.style.color = "#f9e2af";
            }
        }
    }, 1000);updateDownloadButton();

    console.log("✨ Инициализация завершена");// Функция скачивания изображения
function downloadImage(url) {
    const a = document.createElement("a");
    a.href = url;
    a.download = "illustraitor-" + Date.now() + ".png";
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}// Управление кнопкой "Скачать"
function updateDownloadButton() {
    const downloadBtn = document.getElementById("global-download-btn");
    if (!downloadBtn) return;
    const resultContainer = document.getElementById("result-container");
    const hasContent = resultContainer && resultContainer.innerHTML.trim() !== "";
    if (hasContent) {
        // Есть что скачивать - кнопка активна
        downloadBtn.disabled = false;
        downloadBtn.style.background = "#89b4fa";
        downloadBtn.style.color = "#1e1e2e";
        downloadBtn.style.cursor = "pointer";
        downloadBtn.style.opacity = "1";
        downloadBtn.onclick = handleDownload;
    } else {
        // Нечего скачивать - кнопка неактивна
        downloadBtn.disabled = true;
        downloadBtn.style.background = "#6c7086";
        downloadBtn.style.color = "#cdd6f4";
        downloadBtn.style.cursor = "not-allowed";
        downloadBtn.style.opacity = "0.7";
        downloadBtn.onclick = null;
    }
}
// Обработчик скачивания
function handleDownload() {
    const resultContainer = document.getElementById("result-container");
    if (!resultContainer) return;
    const images = resultContainer.getElementsByTagName("img");
    if (images.length > 0 && images[0].src) {
        downloadImage(images[0].src);
    } else {
        alert("❌ Нет изображения для скачивания");
    }
}
// Скачивание изображения
function downloadImage(url) {
    try {
        const a = document.createElement("a");
        a.href = url;
        a.download = \`illustraitor-\${Date.now()}.png\`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        alert("✅ Изображение скачано!");
    } catch (error) {
        console.error("❌ Ошибка скачивания:", error);
        alert("❌ Не удалось скачать изображение");
    }
}


});



