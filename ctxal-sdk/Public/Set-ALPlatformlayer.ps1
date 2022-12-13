function Set-ALPlatformlayer {
  <#
.SYNOPSIS
  Edits values of an platform layer
.DESCRIPTION
  Edits values of an platform layer
.PARAMETER websession
  Existing Webrequest session for ELM Appliance
.PARAMETER id
  ID of the platformlayer to edit
.PARAMETER name
  Name of the platform layer
.PARAMETER description
  Description of the layer
.PARAMETER scriptpath
  Path of script to be run
.PARAMETER icon
  Icon ID
.EXAMPLE
  $platform = Get-ALplatformlayer -websession $websession|where{$_.name -eq "XenDesktop"}
  Set-ALPlatformlayer -websession $websession -name "XenDesktop" -description "Xendesktop-Layer" -id $platform.Id -scriptpath "C:\NeededScript.ps1"
#>
  [cmdletbinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
  Param(
    [Parameter(Mandatory = $true)]$websession,
    [Parameter(Mandatory = $true)][string]$id,
    [Parameter(Mandatory = $false)][string]$name,
    [Parameter(Mandatory = $false)][string]$description,
    [Parameter(Mandatory = $false)][string]$scriptpath,
    [Parameter(Mandatory = $false)][string]$icon
  )
  Begin {
    Write-Verbose "BEGIN: $($MyInvocation.MyCommand)"
    Test-ALWebsession -WebSession $websession
  }
  Process {

    $platformlayer = get-alPlatformlayerdetail -websession $websession -id $id

    #Check for existing params
    if ([string]::IsNullOrWhiteSpace($name)) {
      $name = $platformlayer.LayerSummary.Name
      Write-Verbose "Using existing name value $name"
    }

    if ([string]::IsNullOrWhiteSpace($description)) {
 
      $description = $platformlayer.$description
      if ([string]::IsNullOrWhiteSpace($platformlayer.$description)) {
        $description = ""
      }
      else {
        $description = $platformlayer.description
      }
      Write-Verbose "Using existing description value $description"
    }

    if ([string]::IsNullOrWhiteSpace($scriptpath)) {
      Write-Verbose "Using existing host value"
  
      if ([string]::IsNullOrWhiteSpace($platformlayer.ScriptPath)) {
        $scriptpath = ""
      }
      else {
        $scriptpath = $platformlayer.ScriptPath
      }
      Write-Verbose "Using existing scriptpath value $scriptpath"
    }

    if ([string]::IsNullOrWhiteSpace($icon)) {
  
      $icon = $platformlayer.LayerSummary.ImageId
      Write-Verbose "Using existing icon value $icon"
    }


    [xml]$xml = @"
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/">
  <s:Body xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <EditLayer xmlns="http://www.unidesk.com/">
      <command>
        <Id>$id</Id>
        <Name>$name</Name>
        <Description>$description</Description>
        <IconId>$icon</IconId>
        <ScriptPath>$scriptpath</ScriptPath>
        <Reason>
          <ReferenceNumber>0</ReferenceNumber>
        </Reason>
      </command>
    </EditLayer>
  </s:Body>
</s:Envelope>
"@
    Write-Verbose $xml
    $xml >> "C:\temp\myxml.xml"
    $headers = @{
      SOAPAction     = "http://www.unidesk.com/EditLayer";
      "Content-Type" = "text/xml; charset=utf-8";
      UNIDESK_TOKEN  = $websession.token;
    }

    $url = "https://" + $websession.aplip + "/Unidesk.Web/API.asmx"
    if ($PSCmdlet.ShouldProcess("Setting app layer $name")) {

      $return = Invoke-WebRequest -Uri $url -Method Post -Body $xml -Headers $headers -WebSession $websession
      [xml]$obj = $return.Content

      if ($obj.Envelope.Body.EditLayerResponse.EditLayerResult.Error) {
        throw $obj.Envelope.Body.EditLayerResponse.EditLayerResult.Error.message

      }
      else {
        Write-Verbose "WORKTICKET: $($obj.Envelope.Body.EditLayerResponse.EditLayerResult.WorkTicketId)"
        return $true
      }

    }
  }
  end { Write-Verbose "END: $($MyInvocation.MyCommand)" }
}