// Конфигурация API
const CONFIG = {
    API_BASE_URL: 'https://illustraitor-ai-generator.onrender.com',
    ENDPOINTS: {
        GENERATE: '/generate',
        HEALTH: '/health',
        VALIDATE_OPENAI: '/validate/openai',
        VALIDATE_UNSPLASH: '/validate/unsplash'
    },
    STYLES: [
        { id: 1, name: '🔮 Реализм' },
        { id: 2, name: '🎨 Импрессионизм' },
        { id: 3, name: '🌌 Сюрреализм' },
        { id: 4, name: '🌀 Абстракционизм' },
        { id: 5, name: '🟡 Поп-арт' },
        { id: 6, name: '🤖 Киберпанк' },
        { id: 7, name: '⚙️ Стимпанк' },
        { id: 8, name: '🐉 Фэнтези' },
        { id: 9, name: '🌸 Аниме' },
        { id: 10, name: '🎮 Пиксель-арт' },
        { id: 11, name: '🖌️ Масляная живопись' },
        { id: 12, name: '💧 Акварель' },
        { id: 13, name: '⚫ Черно-белое' },
        { id: 14, name: '📜 Винтаж' },
        { id: 15, name: '📺 Мультяшный' }
    ],
    // Ключи хранения в chrome.storage
    STORAGE_KEYS: {
        OPENAI_KEY: 'openai_key',
        UNSPLASH_KEY: 'unsplash_key',
        LAST_UPDATED: 'last_updated'
    }
};
