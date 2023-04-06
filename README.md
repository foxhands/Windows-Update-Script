# Windows-Update-Script
This PowerShell script automates the process of updating Windows system.
It contains modular code and options for checking internet connection, admin rights, and logging to file.
The script is fast and optimized and also includes a function to clear the log file after execution.

# Installation
- Clone the repository using the command: `git clone https://github.com/foxhands/Windows-Update-Script.git`
- Navigate to the directory containing the script.
- Open PowerShell and run the script using the command: `.\Windows-Update-Script.ps1`

# Usage
The script can be run with various options.
Some can be specified when running the script, while others can be changed within the script:
* -CheckInternetConnection - check internet connection.
* -LogToFile - log script execution to file.

# Examples
```
# Run the script with internet connection check
.\script-name.ps1 -CheckInternetConnection -LogToFile

```

# License
This project is licensed under the MIT License - see the [LICENSE](https://github.com/foxhands/Windows-Update-Script/blob/main/LICENSE) file for details.
