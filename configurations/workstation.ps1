workflow Install-Workflow {

  InlineScript {
    #Register Chocolatly Package source
    Register-PackageSource -Name chocolatey -ProviderName Chocolatey -Location http://chocolatey.org/api/v2/ -Trusted -Force

    #Install packages
    Install-Package -Name GoogleChrome -Source Chocolatey -Force
    Install-Package -Name visualstudiocode -Source Chocolatey -Force
    Install-Package -Name nodejs.install -Source Chocolatey -Force
    Install-Package -Name nvm -Source Chocolatey -Force
    Install-Package -Name visualstudiocode -Source Chocolatey -Force
    Install-Package -Name sysinternals -Source Chocolatey -Force
  }
}
Install-Workflow




