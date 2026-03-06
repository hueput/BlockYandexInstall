# Запускать от имени администратора
#Requires -RunAsAdministrator

Write-Host "Начинаю блокировку Яндекс..." -ForegroundColor Yellow

# Список папок для блокировки
$folders = @(
    "C:\Program Files\Yandex",
    "C:\Program Files (x86)\Yandex",
    "C:\ProgramData\Yandex",
    "$env:APPDATA\Yandex",
    "$env:LOCALAPPDATA\Yandex",
    "$env:USERPROFILE\.yandex",
    "$env:USERPROFILE\AppData\LocalLow\Yandex"
)

foreach ($folder in $folders) {
    Write-Host "Обрабатываю: $folder" -ForegroundColor Cyan
    
    # Создаем папку, если её нет
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Host "  Создана новая папка" -ForegroundColor Green
    }
    
    # Пытаемся очистить разрешения
    try {
        # Сбрасываем разрешения
        $null = icacls $folder /reset /t /c /q 2>$null
        
        # Отключаем наследование
        $null = icacls $folder /inheritance:r /t /c /q 2>$null
        
        # Удаляем доступ для всех групп
        $null = icacls $folder /remove:g "Everyone" /t /c /q 2>$null
        $null = icacls $folder /remove:g "Users" /t /c /q 2>$null
        $null = icacls $folder /remove:g "Пользователи" /t /c /q 2>$null
        $null = icacls $folder /remove:g "Authenticated Users" /t /c /q 2>$null
        
        # Запрещаем доступ всем
        $null = icacls $folder /deny "Everyone:(F,M,RX,W)" /t /c /q 2>$null
        
        # Делаем папку скрытой и системной
        $null = attrib +h +s $folder /s /d 2>$null
        
        Write-Host "  УСПЕШНО ЗАБЛОКИРОВАНО" -ForegroundColor Green
    }
    catch {
        Write-Host "  ОШИБКА: Не удалось заблокировать" -ForegroundColor Red
    }
}

# Дополнительная блокировка через hosts файл
Write-Host "`nБлокирую домены Яндекс в hosts файле..." -ForegroundColor Yellow

$hostsPath = "$env:windir\System32\drivers\etc\hosts"
$yandexDomains = @(
    "0.0.0.0 yandex.ru",
    "0.0.0.0 www.yandex.ru",
    "0.0.0.0 browser.yandex.ru",
    "0.0.0.0 update.yandex.ru",
    "0.0.0.0 download.yandex.ru",
    "0.0.0.0 yastatic.net",
    "0.0.0.0 mc.yandex.ru",
    "0.0.0.0 yandex.com",
    "0.0.0.0 yandex.ua",
    "0.0.0.0 yandex.by",
    "0.0.0.0 yandex.kz"
)

try {
    # Создаем резервную копию hosts
    Copy-Item $hostsPath "$hostsPath.backup" -Force
    
    # Добавляем домены в hosts, если их там нет
    $hostsContent = Get-Content $hostsPath -Raw
    foreach ($domain in $yandexDomains) {
        if ($hostsContent -notmatch [regex]::Escape($domain)) {
            Add-Content -Path $hostsPath -Value $domain
            Write-Host "  Добавлено: $domain" -ForegroundColor Green
        }
    }
}
catch {
    Write-Host "  ОШИБКА: Не удалось изменить hosts файл" -ForegroundColor Red
}

# Создаем файлы-пустышки в системных папках
Write-Host "`nСоздаю дополнительные файлы-блокировки..." -ForegroundColor Yellow

$dummyFiles = @(
    "C:\Windows\System32\drivers\etc\yandex-block.txt",
    "C:\Windows\System32\yandex.exe",
    "C:\Windows\SysWOW64\yandex.exe"
)

foreach ($file in $dummyFiles) {
    if (!(Test-Path $file)) {
        try {
            New-Item -ItemType File -Path $file -Force | Out-Null
            attrib +r +h +s $file
            Write-Host "  Создан файл: $file" -ForegroundColor Green
        }
        catch {
            Write-Host "  Не удалось создать: $file" -ForegroundColor Red
        }
    }
}

Write-Host "`n=====================================" -ForegroundColor Yellow
Write-Host "БЛОКИРОВКА ЗАВЕРШЕНА!" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "Что было сделано:" -ForegroundColor Cyan
Write-Host "✓ Созданы и заблокированы все возможные папки Яндекс"
Write-Host "✓ Заблокированы домены Яндекс в hosts файле"
Write-Host "✓ Созданы файлы-пустышки для дополнительной защиты"
Write-Host ""
Write-Host "Теперь Яндекс не сможет установиться или обновиться!" -ForegroundColor Green
Write-Host ""
Write-Host "Для восстановления удалите папки вручную:" -ForegroundColor Magenta
Write-Host "  C:\Program Files\Yandex"
Write-Host "  C:\ProgramData\Yandex"
Write-Host "  %APPDATA%\Yandex"
Write-Host ""
Read-Host "Нажмите Enter для выхода"
