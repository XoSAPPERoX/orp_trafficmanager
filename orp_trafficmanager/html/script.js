const app = document.getElementById('app');
const menu = document.getElementById('traffic-menu');
const dragHeader = document.getElementById('drag-header');
const closeBtn = document.getElementById('close-btn');
const stopBtn = document.getElementById('stop-traffic');
const slowBtn = document.getElementById('slow-traffic');
const resumeBtn = document.getElementById('resume-traffic');
const radiusSlider = document.getElementById('radius-slider');
const radiusValue = document.getElementById('radius-value');
const zoneStatus = document.getElementById('zone-status');
const placedBy = document.getElementById('placed-by');
const expiresIn = document.getElementById('expires-in');
const statusBadge = document.getElementById('status-badge');
const statusDot = document.getElementById('status-dot');

const STORAGE_KEY = 'traffic_control_menu_position';

let isDragging = false;
let offsetX = 0;
let offsetY = 0;
let currentZone = null;
let expireInterval = null;

function post(action, data = {}) {
    fetch(`https://${GetParentResourceName()}/${action}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
}

function clampPosition(x, y) {
    const maxX = window.innerWidth - menu.offsetWidth;
    const maxY = window.innerHeight - menu.offsetHeight;

    return {
        x: Math.max(0, Math.min(x, maxX)),
        y: Math.max(0, Math.min(y, maxY))
    };
}

function savePosition(x, y) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify({ x, y }));
}

function loadPosition() {
    const saved = localStorage.getItem(STORAGE_KEY);
    if (!saved) return false;

    try {
        const parsed = JSON.parse(saved);
        if (typeof parsed.x !== 'number' || typeof parsed.y !== 'number') {
            return false;
        }

        const clamped = clampPosition(parsed.x, parsed.y);
        menu.style.left = `${clamped.x}px`;
        menu.style.top = `${clamped.y}px`;
        return true;
    } catch {
        return false;
    }
}

function setDefaultPosition() {
    const defaultX = window.innerWidth * 0.76;
    const defaultY = window.innerHeight * 0.18;
    const clamped = clampPosition(defaultX, defaultY);

    menu.style.left = `${clamped.x}px`;
    menu.style.top = `${clamped.y}px`;
}

function ensurePosition() {
    if (!loadPosition()) {
        setDefaultPosition();
    }
}

function updateRadiusLabel() {
    radiusValue.textContent = `${radiusSlider.value}m`;
}

function formatTimeRemaining(expiresAt) {
    if (!expiresAt) return '—';

    const now = Math.floor(Date.now() / 1000);
    const remaining = Math.max(0, expiresAt - now);

    if (remaining <= 0) return 'Expired';

    const minutes = Math.floor(remaining / 60);
    const seconds = remaining % 60;

    return `${minutes}:${String(seconds).padStart(2, '0')}`;
}

function clearExpireTicker() {
    if (expireInterval) {
        clearInterval(expireInterval);
        expireInterval = null;
    }
}

function startExpireTicker() {
    clearExpireTicker();

    expireInterval = setInterval(() => {
        if (!currentZone || !currentZone.expiresAt) {
            expiresIn.textContent = '—';
            clearExpireTicker();
            return;
        }

        expiresIn.textContent = formatTimeRemaining(currentZone.expiresAt);

        const now = Math.floor(Date.now() / 1000);
        if (now >= currentZone.expiresAt) {
            currentZone = null;
            updateZoneStatus(null);
            clearExpireTicker();
        }
    }, 1000);
}

function updateButtonStates(zone) {
    stopBtn.classList.remove('disabled');
    slowBtn.classList.remove('disabled');
    resumeBtn.classList.remove('disabled');

    if (!zone || !zone.mode) {
        resumeBtn.classList.add('disabled');
        return;
    }

    if (zone.mode === 'stop') {
        stopBtn.classList.add('disabled');
    }

    if (zone.mode === 'slow') {
        slowBtn.classList.add('disabled');
    }
}

function updateZoneStatus(zone) {
    currentZone = zone || null;

    statusBadge.className = 'status-badge none';
    statusDot.className = 'status-dot none';

    if (!zone || !zone.mode) {
        zoneStatus.textContent = 'None';
        placedBy.textContent = '—';
        expiresIn.textContent = '—';
        statusBadge.textContent = 'None';
        updateButtonStates(null);
        clearExpireTicker();
        return;
    }

    placedBy.textContent = zone.placedBy || 'Unknown';
    expiresIn.textContent = formatTimeRemaining(zone.expiresAt);

    if (zone.mode === 'stop') {
        zoneStatus.textContent = `Stopped • ${zone.radius}m`;
        statusBadge.textContent = 'Stopped';
        statusBadge.className = 'status-badge stop';
        statusDot.className = 'status-dot stop';
    } else if (zone.mode === 'slow') {
        zoneStatus.textContent = `Slowed • ${zone.radius}m`;
        statusBadge.textContent = 'Slowed';
        statusBadge.className = 'status-badge slow';
        statusDot.className = 'status-dot slow';
    } else {
        zoneStatus.textContent = 'None';
        statusBadge.textContent = 'None';
    }

    updateButtonStates(zone);
    startExpireTicker();
}

function setVisible(state, zone = null) {
    if (state) {
        app.classList.remove('hidden');

        if (zone && zone.radius) {
            radiusSlider.value = zone.radius;
        }

        updateRadiusLabel();
        updateZoneStatus(zone);

        requestAnimationFrame(() => {
            ensurePosition();
        });
    } else {
        app.classList.add('hidden');
    }
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'setVisible') {
        setVisible(data.visible, data.zone || null);
    }

    if (data.action === 'updateZone') {
        updateZoneStatus(data.zone || null);
    }
});

document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        post('close');
    }
});

radiusSlider.addEventListener('input', updateRadiusLabel);

closeBtn.addEventListener('click', () => {
    post('close');
});

stopBtn.addEventListener('click', () => {
    if (stopBtn.classList.contains('disabled')) return;

    post('createZone', {
        mode: 'stop',
        radius: Number(radiusSlider.value)
    });
});

slowBtn.addEventListener('click', () => {
    if (slowBtn.classList.contains('disabled')) return;

    post('createZone', {
        mode: 'slow',
        radius: Number(radiusSlider.value)
    });
});

resumeBtn.addEventListener('click', () => {
    if (resumeBtn.classList.contains('disabled')) return;

    post('resumeTraffic');
});

dragHeader.addEventListener('mousedown', (event) => {
    isDragging = true;

    const rect = menu.getBoundingClientRect();
    offsetX = event.clientX - rect.left;
    offsetY = event.clientY - rect.top;
});

document.addEventListener('mousemove', (event) => {
    if (!isDragging) return;

    const nextX = event.clientX - offsetX;
    const nextY = event.clientY - offsetY;
    const clamped = clampPosition(nextX, nextY);

    menu.style.left = `${clamped.x}px`;
    menu.style.top = `${clamped.y}px`;
});

document.addEventListener('mouseup', () => {
    if (!isDragging) return;

    isDragging = false;

    const rect = menu.getBoundingClientRect();
    savePosition(rect.left, rect.top);
});

window.addEventListener('resize', () => {
    const rect = menu.getBoundingClientRect();
    const clamped = clampPosition(rect.left, rect.top);

    menu.style.left = `${clamped.x}px`;
    menu.style.top = `${clamped.y}px`;
    savePosition(clamped.x, clamped.y);
});

updateRadiusLabel();
ensurePosition();
updateZoneStatus(null);