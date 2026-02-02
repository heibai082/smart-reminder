require('dotenv').config();
const cron = require("node-cron");
const express = require("express");
const fs = require("fs");
const path = require("path");
const dayjs = require("dayjs");

const app = express();
const DATA_DIR = path.join(__dirname, "data");
const TASKS_FILE = path.join(DATA_DIR, "tasks.json");
const CONFIG_FILE = path.join(DATA_DIR, "config.json");
const LOGS_FILE = path.join(DATA_DIR, "logs.json");
const PORT = process.env.PORT || 3166;

app.use(express.json());
app.use(express.static("public"));

// 初始化数据环境
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR);
[TASKS_FILE, LOGS_FILE].forEach(f => { if (!fs.existsSync(f)) fs.writeFileSync(f, "[]"); });
if (!fs.existsSync(CONFIG_FILE)) {
    fs.writeFileSync(CONFIG_FILE, JSON.stringify({ 
        appName: "醒宅家", notifyTime: "08:00", warningDays: 3,
        categories: ["食品", "药品", "化妆品", "其他"] 
    }, null, 2));
}

// 统一日志记录
function addLog(msg) {
    try {
        const logs = JSON.parse(fs.readFileSync(LOGS_FILE));
        logs.unshift({ time: dayjs().format('YYYY-MM-DD HH:mm:ss'), msg });
        fs.writeFileSync(LOGS_FILE, JSON.stringify(logs.slice(0, 200), null, 2));
    } catch (e) { console.error("日志写入失败", e); }
}

const getConfig = () => JSON.parse(fs.readFileSync(CONFIG_FILE));
const getTasks = () => JSON.parse(fs.readFileSync(TASKS_FILE));

async function triggerNotify(title, message) {
    const config = getConfig();
    const body = { title: `[${config.appName}] ${title}`, content: `${message}\n时间: ${dayjs().format('HH:mm:ss')}` };
    try {
        const res = await fetch(process.env.NOTIFY_HOST, {
            method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body)
        });
        const resText = await res.text();
        addLog(`📢 通知成功: ${title} | 响应: ${resText}`);
    } catch (e) { addLog(`❌ 通知失败: ${e.message}`); }
}

// 每小时整点执行 (0 * * * *)
cron.schedule("0 * * * *", () => {
    const config = getConfig();
    if (dayjs().format('HH') === config.notifyTime.split(':')[0]) {
        addLog("⏰ 开始例行过期检查...");
        getTasks().forEach(t => {
            const diff = dayjs(t.expiryDate).diff(dayjs().startOf('day'), 'day');
            if (diff === 0) triggerNotify(`🚨 今日到期`, `【${t.name}】已到期`);
            else if (diff === parseInt(config.warningDays)) triggerNotify(`⚠️ 预警`, `【${t.name}】剩${config.warningDays}天`);
        });
    }
});

app.get("/api/logs", (req, res) => res.json(JSON.parse(fs.readFileSync(LOGS_FILE))));
app.get("/api/config", (req, res) => res.json(getConfig()));
app.post("/api/config", (req, res) => {
    const cfg = { ...getConfig(), ...req.body };
    fs.writeFileSync(CONFIG_FILE, JSON.stringify(cfg, null, 2));
    addLog(`⚙️ 配置已更新`);
    res.json({ code: 200 });
});

app.get("/api/tasks", (req, res) => res.json({ data: getTasks() }));
app.post("/api/assets", (req, res) => {
    const { name, produceDate, shelfLife, category } = req.body;
    const expiryDate = dayjs(produceDate).add(parseInt(shelfLife), 'day').format('YYYY-MM-DD');
    const tasks = getTasks();
    tasks.push({ id: Date.now().toString(), name, category, produceDate, shelfLife, expiryDate });
    fs.writeFileSync(TASKS_FILE, JSON.stringify(tasks, null, 2));
    addLog(`➕ 新增资产: ${name} (${category})`);
    res.json({ code: 200 });
});

app.delete("/api/assets/:id", (req, res) => {
    let tasks = getTasks();
    const item = tasks.find(t => t.id === req.params.id);
    fs.writeFileSync(TASKS_FILE, JSON.stringify(tasks.filter(t => t.id !== req.params.id), null, 2));
    if(item) addLog(`🗑️ 删除资产: ${item.name}`);
    res.json({ code: 200 });
});

app.post("/api/test-notify", async (req, res) => {
    addLog("🧪 发起手动测试...");
    await triggerNotify("手动测试", "测试 Lucky 通道");
    res.json({ code: 200 });
});

app.listen(PORT, '0.0.0.0', () => { addLog("🚀 系统启动，端口: " + PORT); });