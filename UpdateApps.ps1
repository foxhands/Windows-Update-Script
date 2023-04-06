    [CmdletBinding()]
    Param(
        [switch]$CheckInternetConnection,
        [switch]$CheckAdminRights,
        [switch]$LogToFile
    )

    function Log-Message {
        Param(
            [Parameter(Mandatory=$true)]
            [string]$Message
        )
        $currentTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $LogMessage = "[$currentTime] $Message"
        Add-Content -Path $LogPath -Value $LogMessage -Encoding UTF8
    }

    function Check-AdminRights {
        $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

        if (!$isAdmin) {
            Log-Message "Требуются права администратора для выполнения скрипта."
            Write-Error "Требуются права администратора для выполнения скрипта."
            return $false
        }

        return $true
    }

    function Check-InternetConnection {
        $PingResult = Test-NetConnection -ComputerName 'www.google.com' -InformationLevel Quiet
        if ($PingResult -ne 'True') {
            Write-Error "Отсутствует подключение к интернету. Проверьте соединение и повторите попытку."
            return $false
        }

        return $true
    }

    # Функция, которая проверяет, запущен ли сценарий с повышенными правами
    function Test-Admin {
        $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
        $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
    }

    # Функция, которая устанавливает обновления
    function Install-Updates {
        if (Test-Admin) {
            Write-Host "Запущено с правами администратора. Проверяем наличие обновлений..."
            $session = New-Object -ComObject Microsoft.Update.Session
            $searcher = $session.CreateUpdateSearcher()
            $updates = $searcher.Search("IsInstalled=0")
            if ($updates.Updates.Count -eq 0) {
                Write-Host "Нет доступных обновлений для установки."
                return
            }
            Write-Host "Найдено $($updates.Updates.Count) обновлений для установки."
            Write-Host "Начинаем загрузку обновлений..."
            $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
            foreach ($update in $updates.Updates) {
                $updatesToInstall.Add($update)
            }
            $downloader = $session.CreateUpdateDownloader()
            $downloader.Updates = $updatesToInstall
            $downloader.Download()
            Write-Host "Обновления загружены. Начинаем установку..."
            $installer = $session.CreateUpdateInstaller()
            $installer.Updates = $updatesToInstall
            $installationResult = $installer.Install()
            if ($installationResult.ResultCode -eq "2") {
                Write-Host "Установка обновлений потребует перезагрузки. Перезагружаем компьютер..."
                Restart-Computer -Force
            } else {
                Write-Host "Установка обновлений завершена."
            }
        } else {
            Write-Host "Для установки обновлений требуются права администратора."
        }
    }



    $LogPath = 'D:\System\Script\UpdateScript.log'

    # Удаление старого лога, если он существует
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
    }

    # Логирование
    if ($LogToFile) {
        Log-Message "Лог-файл создан: $LogPath"
    }

    # Проверка прав доступа
    if ($CheckAdminRights) {
        if (!(Check-AdminRights)) {
            return
        }
    }

    # Проверка соединения с интернетом
    if ($CheckInternetConnection) {
        if (!(Check-InternetConnection)) {
            return
        }
    }

    # Установка обновлений
    Install-Updates

    #Завершение работы скрипта
    Log-Message "Скрипт успешно выполнен."
    Write-Host "Скрипт успешно выполнен."

    #Приостанавливает выполнение скрипта на 2 секунды
    Start-Sleep -Seconds 2

    # Закрытие окна PowerShell
    Stop-Process -Id $PID
