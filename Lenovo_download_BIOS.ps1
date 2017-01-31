
#---------------------------------------------------------------------------
# Created: Josh Hipple
# Source:  https://github.com/hippman257/LenovoDownloadBIOS
#
#---------------------------------------------------------------------------
# Script to download all BIOS updates for all Lenovo Model.
#
# Parses data that is provided from the Lenovo page:
# "Driver & Software Matrix for IT Admins"
# https://download.lenovo.com/cdrt/tools/drivermatrix/dm.html
#---------------------------------------------------------------------------
# Step #1 - Creates CSV list of models. 
#
# Model,Type
# ThinkCentre M83,10AN
# ThinkCentre M900,10FG
# ThinkPad P50,20EQ
# ThinkPad S1 Yoga,20C0
#---------------------------------------------------------------------------
# Path to CSV file created:
$lenovomodels = "\\serverpath\machine_types.csv"

# Step #2 - Create a folder where the BIOS files will be downloaded:
$downloadpath = "\\serverpath\Lenovo\BIOS\"

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------

$colLenovoModels = @()

$LenovoMachTypes = Import-CSV $lenovomodels

foreach ($LenovoModel in $LenovoMachTypes)
  {
    $objLenovoModel = New-Object System.Object
    $objLenovoModel | Add-Member -type NoteProperty -name Model -value $LenovoModel.Model
    $objLenovoModel | Add-Member -type NoteProperty -name Type -value $LenovoModel.Type

    $url = "https://download.lenovo.com/catalog/" + $LenovoModel.Type + "_win7.xml"
    $machURL  = [xml](new-object system.net.webclient).downloadstring($url)

    $BIOSpath = $machURL.packages.package | where { $_.category.startswith("BIOS") -and $_.location.contains("pccbbs")}

    #Check for multiple BIOS releases
	if ($BIOSpath.count -gt 1) 
	{
        #Record # of BIOS versions
        $objLenovoModel | Add-Member -type NoteProperty -name BIOScount -value $BIOSpath.Count

		$i = 0
		while ($i -lt $BIOSpath.count)
		{ 
            $BIOSpath[$i].location    
		
			$machURLbios  = [xml](new-object system.net.webclient).downloadstring($BIOSpath[$i].location)
			
            $ID = "ID" + $i
			$objLenovoModel | Add-Member -type NoteProperty -name $ID -value $machURLbios.Package.id
			
            $Version = "Version" + $i
        	$objLenovoModel | Add-Member -type NoteProperty -name $Version -value $machURLbios.Package.version
        	
            $ReleaseDate = "ReleaseDate" + $i
        	$objLenovoModel | Add-Member -type NoteProperty -name $ReleaseDate -value $machURLbios.Package.ReleaseDate
            
            $Title = "Title" + $i
            $objLenovoModel | Add-Member -type NoteProperty -name $Title -value $machURLbios.Package.Title.Desc.'#text'
            
            $InstallCmd = "Install" + $i
            $objLenovoModel | Add-Member -type NoteProperty -name $InstallCmd -value $machURLbios.Package.Install.Cmdline.'#text'
            
            $ExtractCommand = "ExtractCommand" + $i
            $objLenovoModel | Add-Member -type NoteProperty -name $ExtractCommand -value $machURLbios.Package.ExtractCommand

            #Download content
            if ($BIOSpath[$i].location.Contains("_gq_2_"))
            {
                $BIOSexe = $BIOSpath[$i].location.Replace("_gq_2_.xml",".exe")
            }
            elseif ($BIOSpath[$i].location.Contains("_b0_2_"))
            {
                $BIOSexe = $BIOSpath[$i].location.Replace("_b0_2_.xml",".exe")
            }
            else
            {
                $BIOSexe = $BIOSpath[$i].location.Replace("_2_.xml",".exe")
            }

            if ($BIOSpath[$i].location.Contains("_gq_2_"))
            {
                $BIOStxt = $BIOSpath[$i].location.Replace("_gq_2_.xml",".txt")
            }
            elseif ($BIOSpath[$i].location.Contains("_b0_2_"))
            {
                $BIOStxt = $BIOSpath[$i].location.Replace("_b0_2_.xml",".txt")
            }
            else
            {
                $BIOStxt = $BIOSpath[$i].location.Replace("_2_.xml",".txt")
            }
            
            $exeval = $LenovoModel.Model + "_(" + $LenovoModel.Type + ")_" + $machURLbios.Package.version + "_" + $machURLbios.Package.ReleaseDate + "_" + $machURLbios.Package.id + ".exe" 
            $path = $downloadpath + $exeval
            Invoke-WebRequest $BIOSexe -OutFile $path
            $FinalEXE = "FinalEXE"  + $i
            $objLenovoModel | Add-Member -type NoteProperty -name $FinalEXE -value $exeval
            
            $txtval = $LenovoModel.Model + "_(" + $LenovoModel.Type + ")_" + $machURLbios.Package.version + "_" + $machURLbios.Package.ReleaseDate + "_" + $machURLbios.Package.id + ".txt" 
            $path = $downloadpath + $txtval
            Invoke-WebRequest $BIOStxt -OutFile $path

			$i+=1
		}
	}
	elseif(!$BIOSpath) #No BIOS info posted
	{
        $objLenovoModel | Add-Member -type NoteProperty -name BIOScount -value 0
        $objLenovoModel | Add-Member -type NoteProperty -name ID -value "No url"
    }
	else #only 1 BIOS release
	{
        $objLenovoModel | Add-Member -type NoteProperty -name BIOScount -value 1

		$machURLbios  = [xml](New-Object system.net.webclient).downloadstring($BIOSpath.location)

	    $objLenovoModel | Add-Member -type NoteProperty -name ID -value $machURLbios.Package.id
	    $objLenovoModel | Add-Member -type NoteProperty -name Version -value $machURLbios.Package.version
	    $objLenovoModel | Add-Member -type NoteProperty -name ReleaseDate -value $machURLbios.Package.ReleaseDate
        $objLenovoModel | Add-Member -type NoteProperty -name Title -value $machURLbios.Package.Title.Desc.'#text'
        $objLenovoModel | Add-Member -type NoteProperty -name InstallCmd -value $machURLbios.Package.Install.Cmdline.'#text' 
        $objLenovoModel | Add-Member -type NoteProperty -name ExtractCmd -value $machURLbios.Package.ExtractCommand

        #Download content
        if ($BIOSpath.location.Contains("_gq_2_"))
        {
            $BIOSexe = $BIOSpath.location.Replace("_gq_2_.xml",".exe")
        }
        elseif ($BIOSpath.location.Contains("_b0_2_"))
        {
            $BIOSexe = $BIOSpath.location.Replace("_b0_2_.xml",".exe")
        }
        else
        {
            $BIOSexe = $BIOSpath.location.Replace("_2_.xml",".exe")
        }

        if ($BIOSpath.location.Contains("_gq_2_"))
        {
            $BIOStxt = $BIOSpath.location.Replace("_gq_2_.xml",".txt")
        }
        elseif ($BIOSpath.location.Contains("_b0_2_"))
        {
            $BIOStxt = $BIOSpath.location.Replace("_b0_2_.xml",".txt")
        }
        else
        {
            $BIOStxt = $BIOSpath.location.Replace("_2_.xml",".txt")
        }

            $exeval = $LenovoModel.Model + "_(" + $LenovoModel.Type + ")_" + $machURLbios.Package.version + "_" + $machURLbios.Package.ReleaseDate + "_" + $machURLbios.Package.id + ".exe" 
            $path = $downloadpath + $exeval
            Invoke-WebRequest $BIOSexe -OutFile $path
            $objLenovoModel | Add-Member -type NoteProperty -name FinalEXE -value $exeval
            
            $txtval = $LenovoModel.Model + "_(" + $LenovoModel.Type + ")_" + $machURLbios.Package.version + "_" + $machURLbios.Package.ReleaseDate + "_" + $machURLbios.Package.id + ".txt" 
            $path = $downloadpath + $txtval
            Invoke-WebRequest $BIOStxt -OutFile $path
	}


    $colLenovoModels += $objLenovoModel
  }
