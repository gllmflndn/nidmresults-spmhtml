%==========================================================================
%Generate an object with the same format as the SPM-output variable, TabDat, 
%using the information from an input NIDM-Results json pack. This takes in 
%one or two arguments:
%
%graph - the nidm-results graph
%exObj - an object containing all information about multiple excursions 
%sets.
%
%Authors: Thomas Maullin, Camille Maumet.
%==========================================================================

function NTabDat = changeNIDMtoTabDat(graph, exObj)
    
    % Checking inputs.
    if nargin == 1
        multipleExcursions = false;
    end
    if nargin == 2
        multipleExcursions = true;
        exNum = exObj{1};
        exLabels = exObj{2};
    end
    
    NTabDat = struct;
    
    %======================================================================
    %tit - the title of the results
    
    titleTemp = 'p-values adjusted for search volume';
    
    %======================================================================
    %nidm - Checking which software was used to generate the NIDM json.
    
    software = '';
    agentObjects = searchforType('prov:SoftwareAgent', graph);
    
    %Check all agent objects for one with the software version stored.
    for i = 1:length(agentObjects)
        soft_type = agentObjects{i}.('x_type');
        if any(ismember(soft_type, 'http://scicrunch.org/resolver/SCR_002823'))...
                || any(ismember(soft_type, 'scr_FSL')) ...
                || any(ismember(soft_type, 'src_FSL'))
            software = 'FSL';
        elseif any(ismember(soft_type, 'http://scicrunch.org/resolver/SCR_007037'))...
                || any(ismember(soft_type, 'scr_SPM')) ...
                || any(ismember(soft_type, 'src_SPM'))
            software = 'SPM';
        % The two options here are assuming analysis software and export
        % software are the same (ideally we should instead explicitely
        % check for the analysis software)
        elseif any(ismember(soft_type, 'nidm_spm_results_nidm'))
            software = 'SPM';
        elseif any(ismember(soft_type, 'nidm_nidmfsl'))
            software = 'FSL';
        else
            disp(soft_type);
            error('nidm:UnrecognisedSoftware', 'Unrecognised software')
        end
    end 
    
    nidmTemp = struct;
    nidmTemp.software = software;
    
    %======================================================================
    %ftr field
   
    ftrTemp = cell(1);
    
    %Height thresholds
    heightThresholds = searchforType('nidm_HeightThreshold', graph);
    if(multipleExcursions)
        heightThresholds = relevantToExcursion(heightThresholds, exNum, exLabels);
    end
    
    %Retrieve the indices of the threshold array which in the following
    %order [FWE, FDR, unCorr, stat] (eg if looking for a threshold of FWE
    %type, look for it's index in the first postion of hPositions). If
    %the statistic type does not exist the position value will be zero.
    hPositions = getThresholdPositions(heightThresholds);
    
    threshList = [];
    
    %If there exists a statistic threshold record it.
    if hPositions(4) ~= 0
        strStat = 'T = %0.2f, ';
        height_1 = get_value(heightThresholds{hPositions(4)}.('prov_value'));
        if(ischar(height_1))
            height_1 = str2double(height_1);
        end
        threshList = [threshList, height_1];
    else
        strStat = '';
    end
    
    %If there exists a unCorrected P-Value threshold record it.
    if hPositions(3) ~= 0
        strPuncorr = 'p = %0.3f';
        height_2 = get_value(heightThresholds{hPositions(3)}.('prov_value'));
        if(ischar(height_2))
            height_2 = str2double(height_2);
        end
        threshList = [threshList, height_2];
    else
        strPuncorr = '';
    end
    
    %If there exists a FWE threshold record it.
    if hPositions(2) ~= 0
        height_3 = get_value(heightThresholds{hPositions(2)}.('prov_value')); 
        if(ischar(height_3))
            height_3 = str2double(height_3);
        end
        strFWEFDR = '(%0.3f FDR)';
        threshList = [threshList, height_3];
    %Else, if there exists a FDR threshold record it.
    elseif hPositions(1) ~= 0
        height_4 = get_value(heightThresholds{hPositions(1)}.('prov_value'));
        if(ischar(height_4))
            height_4 = str2double(height_4);
        end
        strFWEFDR = '(%0.3f FWE)';
        threshList = [threshList, height_4];
    else
        strFWEFDR = '';
    end
    if(~isempty(strStat) || ~isempty(strPuncorr) || ~isempty(strFWEFDR))
        ftrTemp{1, 1} = strcat('Height threshold: ', strStat, strPuncorr, strFWEFDR);
    else
        ftrTemp{1, 1} = '';
    end
    ftrTemp{1, 2} = threshList;
    
    %Extent Threshold
    
    extentThresholds = searchforType('nidm_ExtentThreshold', graph);
    if(multipleExcursions)
        extentThresholds = relevantToExcursion(extentThresholds, exNum, exLabels);
    end
    ePositions = getThresholdPositions(extentThresholds);
    
    %Make the string for displaying extent thresholds and store the extent
    %thresholds themselves.
    if ePositions(4) ~= 0
        ftrTemp{2, 1} = 'Extent threshold: k = %0.0f voxels';  
        kThresh = get_value(extentThresholds{ePositions(4)}.('nidm_clusterSizeInVoxels'));
        if(ischar(kThresh))
            kThresh = str2double(kThresh);
        end
        ftrTemp{2, 2} = kThresh;
    elseif ePositions(1) ~= 0
        ftrTemp{2, 1} = 'Extent threshold: p < %0.0f (FWE)';  
        fweThresh = get_value(extentThresholds{ePositions(1)}.('prov_value'));
        if(ischar(fweThresh))
            fweThresh = str2double(fweThresh);
        end
        ftrTemp{2, 2} = fweThresh;
    elseif ePositions(2) ~= 0
        ftrTemp{2, 1} = 'Extent threshold: p < %0.0f (FDR)';  
        fdrThresh = get_value(extentThresholds{ePositions(2)}.('prov_value'));
        if(ischar(fdrThresh))
            fdrThresh = str2double(fdrThresh);
        end
        ftrTemp{2, 2} = fdrThresh;
    elseif ePositions(3) ~= 0
        ftrTemp{2, 1} = 'Extent threshold: p < %0.0f (Uncorrected)';  
        pThresh = get_value(extentThresholds{ePositions(3)}.('prov_value'));
        if(ischar(pThresh))
            pThresh = str2double(pThresh);
        end
        ftrTemp{2, 2} = pThresh;
    else
        ftrTemp{2, 1} = '';  
        ftrTemp{2, 2} = NaN;
    end
    
    searchSpaceMaskMap = searchforType('nidm_SearchSpaceMaskMap', graph);
    if(multipleExcursions)
        searchSpaceMaskMap = relevantToExcursion(searchSpaceMaskMap, exNum, exLabels);
    end
    
    %Find the searchSpaceMaskMap object linked to the coordinate space.
    searchLinkedToCoord = '';
    for i=1:length(searchSpaceMaskMap)
        if isfield(searchSpaceMaskMap{i}, 'nidm_inCoordinateSpace')
            searchLinkedToCoord = searchSpaceMaskMap{i};
        end
    end
    
    if strcmp(software, 'SPM') 
        
        %Expected voxels per cluster (k)
        ftrTemp{3, 1} = 'Expected voxels per cluster <k> = %0.3f';
        ftrTemp{3, 2} = str2double(get_value(searchLinkedToCoord.('nidm_expectedNumberOfVoxelsPerCluster')));
    
        %Expected number of clusters (c)
        ftrTemp{4, 1} = 'Expected number of clusters <c> = %0.2f';
        ftrTemp{4, 2} = str2double(get_value(searchLinkedToCoord.('nidm_expectedNumberOfClusters')));
    
        %FWEp, FDRp
        FWEp = str2double(get_value(searchLinkedToCoord.('nidm_heightCriticalThresholdFWE05')));
        FDRp = str2double(get_value(searchLinkedToCoord.('nidm_heightCriticalThresholdFDR05')));
        stringTemp = 'FWEp: %0.3f, FDRp: %0.3f';
        arrayTemp = [FWEp, FDRp];
        
        %If its there, include FWEc
        if(isfield(searchLinkedToCoord, 'spm_smallestSignificantClusterSizeInVoxelsFWE05'))
            FWEc = str2double(get_value(searchLinkedToCoord.('spm_smallestSignificantClusterSizeInVoxelsFWE05')));
            stringTemp = [stringTemp, ', FWEc: %0.0f'];
            arrayTemp = [arrayTemp, FWEc];
        end
        
        %If its there, include FDRc
        if(isfield(searchLinkedToCoord, 'spm_smallestSignificantClusterSizeInVoxelsFDR05'))
            FDRc = str2double(get_value(searchLinkedToCoord.('spm_smallestSignificantClusterSizeInVoxelsFDR05')));
            stringTemp = [stringTemp, ', FDRc: %0.0f'];
            arrayTemp = [arrayTemp, FDRc];
        end
    
        ftrTemp{5,1} = stringTemp;
        ftrTemp{5,2} = arrayTemp;
        rowCount = 5;
    else
        rowCount = 2;
    end
    
    %Index of degrees of freedom
    rowCount = rowCount+1;
    effectDegrees = 0;
    errorDegrees = 0;
    
    statisticMap = searchforType('nidm_StatisticMap', graph);
    if(multipleExcursions)
        counter = 1;
        resultant = {};
        %Work out which object belongs to which excursion set.
        for(i = 1:length(statisticMap))
            if(any(ismember(exLabels(statisticMap{i}.prov_wasGeneratedBy.x_id),exNum)))
                resultant{counter} = statisticMap{i};
                counter = counter+1;
            end
        end
        statisticMaps = resultant;
    end

    ftrTemp{rowCount,1} = 'Degrees of freedom = [%0.1f, %0.1f]';
    
    %Find degrees of freedom in statisticMap objects.
    for i = 1:length(statisticMap)
        if isfield(statisticMap{i}, 'nidm_effectDegreesOfFreedom')
            anyStatType = statisticMap{i}.('nidm_statisticType').('x_id');
            if ~strcmp(anyStatType, 'obo:STATO_0000376')
                effectDegrees = get_value(statisticMap{i}.('nidm_effectDegreesOfFreedom'));
                errorDegrees = get_value(statisticMap{i}.('nidm_errorDegreesOfFreedom'));
                if(ischar(errorDegrees))
                    errorDegrees = str2double(errorDegrees);
                    effectDegrees = str2double(effectDegrees);
                end
                ftrTemp{rowCount,2} = [effectDegrees, errorDegrees];
            end
        end
    end 
    
    %FWHM
    
    rowCount = rowCount+1;
    
    %Retrieve the units of the coordinate space.
    searchSpace = searchforID(searchLinkedToCoord.nidm_inCoordinateSpace.('x_id'), graph);
    FWHMUnits = strrep(strrep(strrep(strrep(searchSpace.('nidm_voxelUnits'), '\"', ''), '[', ''), ']', ''), ',', '');
    
    ftrTemp{rowCount, 1} = ['FWHM = %3.1f %3.1f %3.1f ', FWHMUnits '; %3.1f %3.1f %3.1f {voxels}'];
    
    %Store the FWHM in units and voxels
    unitsFWHM = str2num(searchLinkedToCoord.('nidm_noiseFWHMInUnits'));
    voxelsFWHM = str2num(searchLinkedToCoord.('nidm_noiseFWHMInVoxels'));
    
    ftrTemp{rowCount,2} = [unitsFWHM, voxelsFWHM];
    
    %Volume
    
    rowCount = rowCount+1;
    
    volumeUnits = get_value(searchLinkedToCoord.('nidm_searchVolumeInUnits'));
    if(ischar(volumeUnits))
        volumeUnits = str2double(volumeUnits);
    end
    
    volumeResels = get_value(searchLinkedToCoord.('nidm_searchVolumeInResels'));
    if(ischar(volumeResels))
        volumeResels = str2double(volumeResels);
    end
    
    volumeVoxels = get_value(searchLinkedToCoord.('nidm_searchVolumeInVoxels'));
    if(ischar(volumeVoxels))
        volumeVoxels = str2double(volumeVoxels);
    end
    
    ftrTemp{rowCount, 1} = 'Volume: %0.0f = %0.0f voxels = %0.1f resels';
    ftrTemp{rowCount, 2} = [volumeUnits, volumeVoxels, volumeResels];
    
    %Voxel dimensions and resel size
    
    rowCount = rowCount+1;
    voxelSize = str2num(searchSpace.('nidm_voxelSize'));
    voxelUnits = strrep(strrep(strrep(strrep(searchSpace.('nidm_voxelUnits'), '\"', ''), '[', ''), ']', ''), ',', '');
    reselSize = get_value(searchLinkedToCoord.('nidm_reselSizeInVoxels'));
    if(ischar(reselSize))
        reselSize = str2double(reselSize);
    end
    
    ftrTemp{rowCount, 1} = ['Voxel size: %3.1f %3.1f %3.1f ', voxelUnits, '; (resel = %0.2f voxels)'];
    ftrTemp{rowCount, 2} = [voxelSize reselSize];
    
    %======================================================================
    %dat
    
    tableTemp = cell(1);
    
    %Set-level:
    
    %As there are no set level statistics in FSL, set these values to NaN
    %if the nidm pack was generated by FSL.
    if strcmp(software, 'FSL')
        tableTemp{1, 1} = NaN;
        tableTemp{1, 2} = NaN;
    end
    
    %In SPM however the set level statistics are found in the excursion set
    %map in the nidm json.
    if strcmp(software, 'SPM') 
        excursionSetMap = searchforType('nidm_ExcursionSetMap', graph);
        if(multipleExcursions)
            excursionSetMap = relevantToExcursion(excursionSetMap, exNum, exLabels);
        end
        tableTemp{1, 1} = str2double(get_value(excursionSetMap{1}.('nidm_pValue')));
        tableTemp{1, 2} = str2double(get_value(excursionSetMap{1}.('nidm_numberOfSupraThresholdClusters')));
    end
    
    %Cluster and peak level:
    
    clusters = searchforType('nidm_SupraThresholdCluster', graph);
    if(multipleExcursions)
        counter = 1;
        resultant = {};
        %Work out which object belongs to which excursion set.
        for(i = 1:length(clusters))
            excur = searchforID(clusters{i}.prov_wasDerivedFrom.x_id, graph);
            if(any(ismember(exLabels(excur.prov_wasGeneratedBy.x_id),exNum)))
                resultant{counter} = clusters{i};
                counter = counter+1;
            end
        end
        clusters = resultant;
    end
    
    peakDefCriteria = searchforType('nidm_PeakDefinitionCriteria', graph);
    if(multipleExcursions)
        peakDefCriteria = relevantToExcursion(peakDefCriteria, exNum, exLabels);
    end
    
    %Obtain what type of statistic we are dealing with:    
    statType = getStatType(graph);
    
    if~isempty(clusters)
        
        %Sorting the clusters by descending size.
        oo=cellfun(@(x) get_value(x.('nidm_clusterSizeInVoxels')), clusters, 'UniformOutput', false);
        aa=str2num(char(oo{:}));
        [~, idx]=sort(aa, 'descend');
        clusters = clusters(idx);

        %Create keySet and valueSet
        keySet = cellfun(@(x) x.('x_id'), clusters, 'UniformOutput', false);
        valueSet = NaN(1, length(keySet));

        clusterPeakMap = containers.Map(keySet, valueSet, 'UniformValues', false);
        peaks = searchforType('nidm_Peak', graph);

        for i = 1:length(peaks)
            clusterID = peaks{i}.('prov_wasDerivedFrom').('x_id');
            if(isKey(clusterPeakMap, clusterID))
                if isa(clusterPeakMap(clusterID), 'double')
                    clusterPeakMap(clusterID) = {peaks{i}};
                else
                    existing = clusterPeakMap(clusterID);
                    clusterPeakMap(clusterID) = {existing{:} peaks{i}};
                end
            end
        end

        %Sorting the peaks within clusters.
        for i = 1:length(keySet)
            clusterID = keySet{i};
            clustmaptemp=clusterPeakMap(clusterID);
            clusSet=cellfun(@(x) get_value(x.('nidm_equivalentZStatistic')), clustmaptemp, 'UniformOutput', false);
            orderedClusSet=str2num(char(clusSet{:}));
            [~, idx]=sort(orderedClusSet, 'descend');
            clusterPeakMap(clusterID) = clustmaptemp(idx);
        end
    
        %Read data from the cluster-peak hash-map created above.
        n = 1;
        
        %Check whether clusters have values stored.
        clustersFDRP = isfield(clusters{1}, 'nidm_qValueFDR');
        clustersPUncorr = isfield(clusters{1}, 'nidm_pValueUncorrected');
        
        %Check whether peaks have values stored.
        peaksFWEP = isfield(peaks{1}, 'nidm_pValueFWER');
        peaksFDRP = isfield(peaks{1}, 'nidm_qValueFDR');
        peaksStat = isfield(peaks{1}, 'prov_value');
        
        %Get number of peaks to display
        if isfield(peakDefCriteria{1}, 'nidm_maxNumberOfPeaksPerCluster')
            numOfPeaks = get_value(peakDefCriteria{1}.nidm_maxNumberOfPeaksPerCluster);
        else
            numOfPeaks = 3;
        end 
        
        for i = 1:length(keySet)
            %Fill in the values we know.
            tableTemp{n, 3} = str2double(get_value(clusters{i}.('nidm_pValueFWER')));
            if clustersFDRP
                tableTemp{n, 4} = str2double(get_value(clusters{i}.('nidm_qValueFDR')));
            else
                tableTemp{n, 4} = NaN;
            end
            tableTemp{n, 5} = str2double(get_value(clusters{i}.('nidm_clusterSizeInVoxels')));
            if clustersPUncorr
                tableTemp{n, 6} = str2double(get_value(clusters{i}.('nidm_pValueUncorrected')));
            else
                tableTemp{n, 6} = NaN;
            end
            peaksTemp = clusterPeakMap(keySet{i});
        
            for j = 1:min(numOfPeaks, length(peaksTemp))
                %Fill the values we know.
                if peaksFWEP
                    tableTemp{n, 7} = str2double(get_value(peaksTemp{j}.('nidm_pValueFWER')));
                end
                if peaksFDRP
                    tableTemp{n, 8} = str2double(get_value(peaksTemp{j}.('nidm_qValueFDR')));
                end
                tableTemp{n, 11} = str2double(get_value(peaksTemp{j}.('nidm_pValueUncorrected')));
                if peaksStat
                    tableTemp{n, 9} = str2double(get_value(peaksTemp{j}.('prov_value')));
                else
                    %Calculate whichever statistic type is used.
                    if strcmp(statType, 'T')
                        tableTemp{n, 9} = icdf('T',1-tableTemp{n, 11},errorDegrees);
                    elseif strcmp(statType, 'X')
                        tableTemp{n, 9} = icdf('Chi',1-tableTemp{n, 11},errorDegrees);
                    elseif strcmp(statType, 'F')
                        tableTemp{n, 9} = icdf('F',1-tableTemp{n, 11},effectDegrees, errorDegrees);
                    else
                        tableTemp{n, 9} = NaN;
                    end
                end 
                tableTemp{n, 10} = str2double(get_value(peaksTemp{j}.('nidm_equivalentZStatistic')));
                locTemp = peaksTemp{j}.('prov_atLocation').('x_id');
                locTemp = searchforID(locTemp, graph);
                tableTemp{n, 12} = str2num(locTemp.nidm_coordinateVector);
                n = n+1;
             end
        end
        
        [height, ~] = size(tableTemp);
        
        %Otherwise fill the gaps with NaN.
        if ~peaksFWEP
            [tableTemp{1:height, 7}] = deal(NaN);
        end
        if ~peaksFDRP
            [tableTemp{1:height, 8}] = deal(NaN);
        end
        
    else
        %If no cluster values are available set the remaining values in the
        %first row of the table to NaN.
        for i = 3:13
            tableTemp{1, i} = NaN;
        end
    end
    
    %===========================================
    %str field
    
    
    if(~isempty(peakDefCriteria))
        units = strtok(voxelUnits, ' ');
        minDist = get_value(peakDefCriteria{1}.nidm_minDistanceBetweenPeaks);
        if(~ischar(minDist))
            minDist = num2str(minDist);
        end
        if isfield(peakDefCriteria{1}, 'nidm_maxNumberOfPeaksPerCluster')
            clusNum = get_value(peakDefCriteria{1}.nidm_maxNumberOfPeaksPerCluster);
            if(~ischar(clusNum))
                clusNum = num2str(clusNum);
            end
            strTemp = ['table shows ', clusNum, ' local maxima more than ', minDist, units, ' apart'];
        else
            strTemp = ['table shows 3 local maxima more than ', minDist, units, ' apart'];
        end
    else 
        strTemp = '';
    end
    
    %======================================================================
    %fmt
    
    fmtTemp = {'%-0.3f' '%g' '%0.3f' '%0.3f' '%0.0f' '%0.3f' '%0.3f' '%0.3f' '%6.2f' '%5.2f' '%0.3f' '%3.0f %3.0f %3.0f '};
    
    %======================================================================
    
    NTabDat.tit = titleTemp;
    NTabDat.dat = tableTemp;
    NTabDat.ftr = ftrTemp;
    NTabDat.str = strTemp;
    NTabDat.fmt = fmtTemp;
    NTabDat.nidm = nidmTemp;
end