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

    function Install-Updates {
        Write-Output 'Поиск доступных обновлений...'
        $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0")

        # Проверка наличия обновлений
        if ($updates.Updates.Count -eq 0) {
            Log-Message "Нет доступных обновлений."
            Write-Host "Нет доступных обновлений."
        } else {
            Log-Message "Найдено $($updates.Updates.Count) обновлений."
            $updates.Updates | foreach {
                $_.AcceptEula()
                Log-Message "Установка обновления $($_.Title)..."
                (New-Object -ComObject Microsoft.Update.UpdateInstaller).Install($updates)
            }
            Log-Message "Все обновления установлены."
            Write-Host "Все обновления установлены."
            # Проверка успешности выполнения обновлений
            $success = $updates.Updates | Where-Object {$_.IsInstalled -eq $false}
            if ($success.Count -eq 0) {
                Log-Message "Все обновления установлены успешно."
                Write-Host "Все обновления установлены успешно."
            } else {
                Log-Message "Не все обновления были установлены."
                Write-Error "Не все обновления были установлены."
            }
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