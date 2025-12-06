classdef EngineTemperatureTab < handle
    % EngineTemperatureTab
    % Tab to analyze engine water and oil temperatures based on:
    %   - Air temp
    %   - Water & Oil radiator tapes
    %   - Bellypan tape
    %   - Sponge (L / M / NONE)
    %   - Slipstream (0/1)
    %   - Time (1 = long session)
    
    properties
        ParentTabGroup
        ParentFigure
        Tab
        
        MainGrid
        
        % Top filter panel
        FilterPanel
        SpongeFilterDropDown
        SlipstreamFilterDropDown
        SessionFilterDropDown
        ReloadButton
        LoadButton
        SaveButton
        
        % Summary panel
        SummaryPanel
        SpongeSummaryTable
        SlipstreamSummaryTable
        
        % Raw data table
        RawPanel
        RawTable
        
        % Plots
        AxesWater
        AxesOil
        
        % Data
        CsvPath
        Data table
        FilteredRowIndices % Track which rows in obj.Data correspond to filtered display
    end
    
    methods
        function obj = EngineTemperatureTab(tabGroup, parentFigure, csvPath)
            obj.ParentTabGroup = tabGroup;
            obj.ParentFigure   = parentFigure;
            obj.CsvPath        = csvPath;
            
            obj.createUI();
            obj.loadData();
            obj.configureSessionFilter();
            obj.refreshAll();
        end
    end
    
    methods (Access = private)
        
        function createUI(obj)
            % Create tab
            obj.Tab = uitab(obj.ParentTabGroup);
            obj.Tab.Title = 'Engine Temperature';
            
            % Main grid layout: 4 rows x 2 columns (added row for summary panel expansion)
            obj.MainGrid = uigridlayout(obj.Tab, [4 2]);
            obj.MainGrid.RowHeight   = {75, 75, '1x', '1x'}; % Row 1: 75px (filter), Row 2: 75px (summary = 150px total)
            obj.MainGrid.ColumnWidth = {'1.5x', '1x'};
            
            %% Top filter panel (row 1, col 1)
            obj.FilterPanel = uipanel(obj.MainGrid);
            obj.FilterPanel.Title = 'Filters';
            obj.FilterPanel.Layout.Row = 1;
            obj.FilterPanel.Layout.Column = 1;
            
            filterGrid = uigridlayout(obj.FilterPanel, [1 9]);
            % Dropdown columns are 1/3 smaller (2/3 of original size)
            % Columns: Sponge label, Sponge dropdown, Slipstream label, Slipstream dropdown, 
            %          Session label, Session dropdown, Reload button, Load button, Save button
            % Making dropdown columns smaller - using 0.5x to ensure they're actually smaller
            filterGrid.ColumnWidth = {'fit', '0.5x', 'fit', '0.5x', 'fit', '0.5x', 'fit', 'fit', 'fit'};
            
            % Sponge filter
            uilabel(filterGrid, 'Text', 'Sponge', 'HorizontalAlignment', 'center');
            obj.SpongeFilterDropDown = uidropdown(filterGrid, ...
                'Items', {'All', 'L', 'M', 'NONE'}, ...
                'Value', 'All', ...
                'ValueChangedFcn', @(dd, event) obj.onFilterChanged());
            
            % Slipstream filter
            uilabel(filterGrid, 'Text', 'Slipstream', 'HorizontalAlignment', 'center');
            obj.SlipstreamFilterDropDown = uidropdown(filterGrid, ...
                'Items', {'All', 'No slipstream (0)', 'Slipstream (1)'}, ...
                'Value', 'All', ...
                'ValueChangedFcn', @(dd, event) obj.onFilterChanged());
            
            % Session filter
            uilabel(filterGrid, 'Text', 'Session', 'HorizontalAlignment', 'center');
            obj.SessionFilterDropDown = uidropdown(filterGrid, ...
                'Items', {'All'}, ...
                'Value', 'All', ...
                'ValueChangedFcn', @(dd, event) obj.onFilterChanged());
            
            % Reload button
            obj.ReloadButton = uibutton(filterGrid, ...
                'Text', 'Reload CSV', ...
                'ButtonPushedFcn', @(btn, event) obj.onReloadButtonPushed());
            
            % Load button
            obj.LoadButton = uibutton(filterGrid, ...
                'Text', 'Load', ...
                'ButtonPushedFcn', @(btn, event) obj.onLoadButtonPushed());
            
            % Save button
            obj.SaveButton = uibutton(filterGrid, ...
                'Text', 'Save', ...
                'ButtonPushedFcn', @(btn, event) obj.onSaveButtonPushed());
            
            %% Summary panel (rows 1-2, col 2) - 1/4 taller than filter panel
            obj.SummaryPanel = uipanel(obj.MainGrid);
            obj.SummaryPanel.Title = 'Summary (Means by Sponge / Slipstream)';
            obj.SummaryPanel.Layout.Row = [1 2];
            obj.SummaryPanel.Layout.Column = 2;
            
            summaryGrid = uigridlayout(obj.SummaryPanel, [1 2]);
            summaryGrid.ColumnWidth = {'1x', '1x'};
            
            % Sponge summary table
            obj.SpongeSummaryTable = uitable(summaryGrid, ...
                'ColumnEditable', false, ...
                'RowName', []);
            obj.SpongeSummaryTable.Layout.Row = 1;
            obj.SpongeSummaryTable.Layout.Column = 1;
            
            % Slipstream summary table
            obj.SlipstreamSummaryTable = uitable(summaryGrid, ...
                'ColumnEditable', false, ...
                'RowName', []);
            obj.SlipstreamSummaryTable.Layout.Row = 1;
            obj.SlipstreamSummaryTable.Layout.Column = 2;
            
            %% Raw data panel (rows 2–4, col 1)
            obj.RawPanel = uipanel(obj.MainGrid);
            obj.RawPanel.Title = 'Raw Engine Temperature Data (CSV)';
            obj.RawPanel.Layout.Row = [2 4];
            obj.RawPanel.Layout.Column = 1;
            obj.RawPanel.Scrollable = 'on'; % allow vertical scrolling when many rows
            
            rawGrid = uigridlayout(obj.RawPanel, [1 1]);
            rawGrid.RowHeight   = {'1x'};
            rawGrid.ColumnWidth = {'1x'};
            
            obj.RawTable = uitable(rawGrid, ...
                'ColumnEditable', true, ...
                'RowName', [], ...
                'CellEditCallback', @(src, event) obj.onTableCellEdit(src, event));
            obj.RawTable.Layout.Row = 1;
            obj.RawTable.Layout.Column = 1;
            
            % NOTE: width is up to column J because the data itself only has
            % 10 columns; the table will automatically size to show them.
            obj.RawTable.ColumnWidth = 'auto';
            
            % Apply center alignment style to all cells
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.RawTable, centerStyle);
            
            %% Water temp plot (row 3, col 2) - moved down since summary spans rows 1-2
            obj.AxesWater = uiaxes(obj.MainGrid);
            obj.AxesWater.Layout.Row = 3;
            obj.AxesWater.Layout.Column = 2;
            title(obj.AxesWater, 'Water temp vs Air temp');
            xlabel(obj.AxesWater, 'Air temp [°C]');
            ylabel(obj.AxesWater, 'Water temp [°C]');
            grid(obj.AxesWater, 'on');
            xlim(obj.AxesWater, [0 50]);
            ylim(obj.AxesWater, [50 100]);
            
            %% Oil temp plot (row 4, col 2)
            obj.AxesOil = uiaxes(obj.MainGrid);
            obj.AxesOil.Layout.Row = 4;
            obj.AxesOil.Layout.Column = 2;
            title(obj.AxesOil, 'Oil temp vs Air temp');
            xlabel(obj.AxesOil, 'Air temp [°C]');
            ylabel(obj.AxesOil, 'Oil temp [°C]');
            grid(obj.AxesOil, 'on');
            xlim(obj.AxesOil, [0 50]);
            ylim(obj.AxesOil, [90 130]);
        end
        
        function loadData(obj)
            if isfile(obj.CsvPath)
                try
                    T = readtable(obj.CsvPath);
                catch ME
                    warning('EngineTemperatureTab:ReadError', ...
                        'Error reading %s: %s', obj.CsvPath, ME.message);
                    T = table();
                end
            else
                warning('EngineTemperatureTab:CSVNotFound', ...
                    'CSV file not found at: %s', obj.CsvPath);
                T = table();
            end
            obj.Data = T;
        end
        
        function configureSessionFilter(obj)
            dd = obj.SessionFilterDropDown;
            if isempty(obj.Data) || ~ismember('Session', obj.Data.Properties.VariableNames)
                dd.Items = {'All'};
                dd.Value = 'All';
            else
                sessions = unique(obj.Data.Session, 'stable');
                sessionsStr = cellstr(string(sessions));
                dd.Items = ['All', sessionsStr'];
                if ~ismember(dd.Value, dd.Items)
                    dd.Value = 'All';
                end
            end
        end
        
        function T = getFilteredData(obj)
            T = obj.Data;
            if isempty(T)
                return;
            end
            
            % Store original indices before filtering
            originalIndices = (1:height(T))';
            
            % Sponge filter
            spongeValue = obj.SpongeFilterDropDown.Value;
            if ~strcmp(spongeValue, 'All') && ismember('Sponge', T.Properties.VariableNames)
                if strcmp(spongeValue, 'NONE')
                    % rows with empty or missing sponge (if you ever add them)
                    mask = ismissing(T.Sponge) | strcmpi(strtrim(string(T.Sponge)), '');
                    T = T(mask, :);
                    originalIndices = originalIndices(mask);
                else
                    mask = strcmp(string(T.Sponge), spongeValue);
                    T = T(mask, :);
                    originalIndices = originalIndices(mask);
                end
            end
            
            % Slipstream filter
            slipValue = obj.SlipstreamFilterDropDown.Value;
            if ismember('Slipstream', T.Properties.VariableNames)
                switch slipValue
                    case 'No slipstream (0)'
                        mask = T.Slipstream == 0;
                        T = T(mask, :);
                        originalIndices = originalIndices(mask);
                    case 'Slipstream (1)'
                        mask = T.Slipstream == 1;
                        T = T(mask, :);
                        originalIndices = originalIndices(mask);
                    otherwise
                        % 'All' -> no extra filter
                end
            end
            
            % Session filter
            sessValue = obj.SessionFilterDropDown.Value;
            if ~strcmp(sessValue, 'All') && ismember('Session', T.Properties.VariableNames)
                mask = strcmp(string(T.Session), sessValue);
                T = T(mask, :);
                originalIndices = originalIndices(mask);
            end
            
            % Store the mapping from filtered rows to original rows
            obj.FilteredRowIndices = originalIndices;
        end
        
        function refreshAll(obj)
            T = obj.getFilteredData();
            % Note: getFilteredData() now sets obj.FilteredRowIndices
            obj.updateRawTable(T);
            obj.updateSpongeSummary(T);
            obj.updateSlipstreamSummary(T);
            obj.updatePlots(T);
        end
        
        function updateRawTable(obj, T)
            if isempty(T)
                obj.RawTable.Data = {};
                obj.RawTable.ColumnName = {};
                obj.RawTable.ColumnEditable = [];
                obj.RawTable.ColumnFormat = {};
            else
                % Format numeric columns to one decimal place
                T_formatted = obj.formatTableForDisplay(T);
                
                % Determine which columns are editable (all except row identifiers if any)
                numCols = width(T);
                editable = true(1, numCols);
                
                % Set column formats for proper display
                colFormats = cell(1, numCols);
                varNames = T.Properties.VariableNames;
                for i = 1:numCols
                    colData = T.(varNames{i});
                    formattedColData = T_formatted.(varNames{i});
                    if isnumeric(colData) && ~islogical(colData)
                        % Numeric columns are formatted as cell arrays of strings
                        colFormats{i} = 'char';
                    elseif islogical(colData)
                        colFormats{i} = 'logical';
                    else
                        colFormats{i} = 'char';
                    end
                end
                
                obj.RawTable.Data = T_formatted;
                obj.RawTable.ColumnName = T.Properties.VariableNames;
                obj.RawTable.ColumnEditable = editable;
                obj.RawTable.ColumnFormat = colFormats;
            end
        end
        
        function T_formatted = formatTableForDisplay(obj, T)
            %FORMATTABLEFORDISPLAY Format table for display with one decimal place for numbers
            %   Returns a table with numeric columns formatted as strings with one decimal
            T_formatted = T;
            varNames = T.Properties.VariableNames;
            
            for i = 1:width(T)
                colData = T.(varNames{i});
                if isnumeric(colData) && ~islogical(colData)
                    % Format numeric columns to one decimal place
                    % Convert to string with one decimal, handling NaN
                    formatted = cell(height(T), 1);
                    for j = 1:height(T)
                        if isnan(colData(j))
                            formatted{j} = '';
                        else
                            formatted{j} = sprintf('%.1f', colData(j));
                        end
                    end
                    T_formatted.(varNames{i}) = formatted;
                end
            end
        end
        
        function T_numeric = unformatTableFromDisplay(obj, T_formatted, T_original)
            %UNFORMATTABLEFROMDISPLAY Convert formatted display table back to numeric
            %   T_formatted: table with formatted strings
            %   T_original: original table with numeric types
            T_numeric = T_original;
            varNames = T_original.Properties.VariableNames;
            
            for i = 1:width(T_original)
                if isnumeric(T_original.(varNames{i})) && ~islogical(T_original.(varNames{i}))
                    % Convert formatted strings back to numbers
                    formattedData = T_formatted.(varNames{i});
                    numericData = nan(height(T_original), 1);
                    for j = 1:height(T_original)
                        if iscell(formattedData)
                            val = formattedData{j};
                        else
                            val = formattedData(j);
                        end
                        if ischar(val) || isstring(val)
                            valStr = string(val);
                            if valStr == "" || ismissing(valStr)
                                numericData(j) = nan;
                            else
                                numericData(j) = str2double(valStr);
                            end
                        else
                            numericData(j) = val;
                        end
                    end
                    T_numeric.(varNames{i}) = numericData;
                elseif iscell(T_formatted.(varNames{i}))
                    % For cell arrays, extract the actual values
                    cellData = T_formatted.(varNames{i});
                    if iscell(cellData)
                        T_numeric.(varNames{i}) = cellData;
                    else
                        T_numeric.(varNames{i}) = T_formatted.(varNames{i});
                    end
                else
                    T_numeric.(varNames{i}) = T_formatted.(varNames{i});
                end
            end
        end
        
        function updateSpongeSummary(obj, T)
            if isempty(T) || ~ismember('Sponge', T.Properties.VariableNames)
                obj.SpongeSummaryTable.Data = {};
                obj.SpongeSummaryTable.ColumnName = {};
                return;
            end
            
            % Only keep rows where water/oil temps exist
            % Try both column name formats
            if ismember('Water temp', T.Properties.VariableNames)
                w = T.("Water temp");
            elseif ismember('WaterTemp', T.Properties.VariableNames)
                w = T.("WaterTemp");
            else
                w = [];
            end
            if ismember('Oil temp', T.Properties.VariableNames)
                o = T.("Oil temp");
            elseif ismember('OilTemp', T.Properties.VariableNames)
                o = T.("OilTemp");
            else
                o = [];
            end
            
            if isempty(w) || isempty(o)
                obj.SpongeSummaryTable.Data = {};
                obj.SpongeSummaryTable.ColumnName = {};
                return;
            end
            
            [G, sponges] = findgroups(T.Sponge);
            meanWater = splitapply(@mean, w, G);
            meanOil   = splitapply(@mean, o, G);
            
            % Optional: differences vs M
            spongeStr = string(sponges);
            dWater = nan(size(meanWater));
            dOil   = nan(size(meanOil));
            idxM = find(spongeStr == "M", 1);
            if ~isempty(idxM)
                dWater = meanWater - meanWater(idxM);
                dOil   = meanOil   - meanOil(idxM);
            end
            
            summary = table(spongeStr, meanWater, meanOil, dWater, dOil, ...
                'VariableNames', {'Sponge', 'MeanWaterTemp', 'MeanOilTemp', ...
                                  'DeltaWater_vs_M', 'DeltaOil_vs_M'});
            
            obj.SpongeSummaryTable.Data = summary;
            obj.SpongeSummaryTable.ColumnName = summary.Properties.VariableNames;
        end
        
        function updateSlipstreamSummary(obj, T)
            if isempty(T) || ~ismember('Slipstream', T.Properties.VariableNames)
                obj.SlipstreamSummaryTable.Data = {};
                obj.SlipstreamSummaryTable.ColumnName = {};
                return;
            end
            
            % Try both column name formats
            if ismember('Water temp', T.Properties.VariableNames)
                w = T.("Water temp");
            elseif ismember('WaterTemp', T.Properties.VariableNames)
                w = T.("WaterTemp");
            else
                w = [];
            end
            if ismember('Oil temp', T.Properties.VariableNames)
                o = T.("Oil temp");
            elseif ismember('OilTemp', T.Properties.VariableNames)
                o = T.("OilTemp");
            else
                o = [];
            end
            
            if isempty(w) || isempty(o)
                obj.SlipstreamSummaryTable.Data = {};
                obj.SlipstreamSummaryTable.ColumnName = {};
                return;
            end
            
            [G, slipVals] = findgroups(T.Slipstream);
            meanWater = splitapply(@mean, w, G);
            meanOil   = splitapply(@mean, o, G);
            
            slipStr = "Slip " + string(slipVals);
            summary = table(slipStr, slipVals, meanWater, meanOil, ...
                'VariableNames', {'SlipLabel', 'Slipstream', 'MeanWaterTemp', 'MeanOilTemp'});
            
            obj.SlipstreamSummaryTable.Data = summary;
            obj.SlipstreamSummaryTable.ColumnName = summary.Properties.VariableNames;
        end
        
        function updatePlots(obj, T)
            cla(obj.AxesWater);
            cla(obj.AxesOil);
            
            % Try both column name formats (with and without spaces)
            airColName = '';
            if ismember('Air temp', T.Properties.VariableNames)
                airColName = 'Air temp';
            elseif ismember('AirTemp', T.Properties.VariableNames)
                airColName = 'AirTemp';
            end
            
            if isempty(T) || isempty(airColName)
                return;
            end
            
            air = T.(airColName);
            
            % Filter out NaN values
            validIdx = ~isnan(air);
            if ~any(validIdx)
                return;
            end
            air = air(validIdx);
            T_filtered = T(validIdx, :);
            
            % Water
            waterColName = '';
            if ismember('Water temp', T.Properties.VariableNames)
                waterColName = 'Water temp';
            elseif ismember('WaterTemp', T.Properties.VariableNames)
                waterColName = 'WaterTemp';
            end
            
            if ~isempty(waterColName) && ismember(waterColName, T_filtered.Properties.VariableNames)
                w = T_filtered.(waterColName);
                % Filter out NaN values for water temp
                validWaterIdx = ~isnan(w);
                if any(validWaterIdx)
                    w = w(validWaterIdx);
                    air_water = air(validWaterIdx);
                    T_water = T_filtered(validWaterIdx, :);
                    
                    % Plot by sponge type
                    if ismember('Sponge', T_water.Properties.VariableNames)
                        sp = string(T_water.Sponge);
                        spongeTypes = unique(sp(~ismissing(sp)), 'stable');
                        hold(obj.AxesWater, 'on');
                        for k = 1:numel(spongeTypes)
                            mask = sp == spongeTypes(k);
                            if any(mask)
                                plot(obj.AxesWater, air_water(mask), w(mask), 'o-', ...
                                    'DisplayName', char(spongeTypes(k)), 'LineWidth', 1.5, 'MarkerSize', 6);
                            end
                        end
                        hold(obj.AxesWater, 'off');
                        legend(obj.AxesWater, 'Location', 'best');
                    else
                        % No sponge column, just plot all points
                        plot(obj.AxesWater, air_water, w, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
                    end
                end
            end
            
            % Oil
            oilColName = '';
            if ismember('Oil temp', T.Properties.VariableNames)
                oilColName = 'Oil temp';
            elseif ismember('OilTemp', T.Properties.VariableNames)
                oilColName = 'OilTemp';
            end
            
            if ~isempty(oilColName) && ismember(oilColName, T_filtered.Properties.VariableNames)
                o = T_filtered.(oilColName);
                % Filter out NaN values for oil temp
                validOilIdx = ~isnan(o);
                if any(validOilIdx)
                    o = o(validOilIdx);
                    air_oil = air(validOilIdx);
                    T_oil = T_filtered(validOilIdx, :);
                    
                    % Plot by sponge type
                    if ismember('Sponge', T_oil.Properties.VariableNames)
                        sp = string(T_oil.Sponge);
                        spongeTypes = unique(sp(~ismissing(sp)), 'stable');
                        hold(obj.AxesOil, 'on');
                        for k = 1:numel(spongeTypes)
                            mask = sp == spongeTypes(k);
                            if any(mask)
                                plot(obj.AxesOil, air_oil(mask), o(mask), 'o-', ...
                                    'DisplayName', char(spongeTypes(k)), 'LineWidth', 1.5, 'MarkerSize', 6);
                            end
                        end
                        hold(obj.AxesOil, 'off');
                        legend(obj.AxesOil, 'Location', 'best');
                    else
                        % No sponge column, just plot all points
                        plot(obj.AxesOil, air_oil, o, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6);
                    end
                end
            end
            
            % Reset axis limits
            xlim(obj.AxesWater, [0 50]);
            ylim(obj.AxesWater, [50 100]);
            xlim(obj.AxesOil, [0 50]);
            ylim(obj.AxesOil, [90 130]);
        end
        
        %% Callbacks
        
        function onFilterChanged(obj)
            obj.refreshAll();
        end
        
        function onReloadButtonPushed(obj)
            obj.loadData();
            obj.configureSessionFilter();
            obj.refreshAll();
        end
        
        function onLoadButtonPushed(obj)
            %ONLOADBUTTONPUSHED Load data from enginetemperature.csv automatically
            try
                if isfile(obj.CsvPath)
                    T = readtable(obj.CsvPath);
                    obj.Data = T;
                    obj.configureSessionFilter();
                    obj.refreshAll();
                else
                    uialert(obj.ParentFigure, ...
                        sprintf('CSV file not found at: %s', obj.CsvPath), ...
                        'Load Error', 'Icon', 'warning');
                end
            catch ME
                uialert(obj.ParentFigure, ...
                    sprintf('Error loading CSV file:\n%s', ME.message), ...
                    'Load Error', 'Icon', 'error');
            end
        end
        
        function onSaveButtonPushed(obj)
            %ONSAVEBUTTONPUSHED Save current table data to enginetemperature.csv automatically
            try
                % Update Data from table to ensure we have the latest edits
                obj.updateDataFromTable();
                if ~isempty(obj.Data)
                    writetable(obj.Data, obj.CsvPath);
                else
                    uialert(obj.ParentFigure, ...
                        'No data to save', 'Save Error', 'Icon', 'warning');
                end
            catch ME
                uialert(obj.ParentFigure, ...
                    sprintf('Error saving CSV file:\n%s', ME.message), ...
                    'Save Error', 'Icon', 'error');
            end
        end
        
        function onTableCellEdit(obj, src, event)
            %ONTABLECELLEDIT Handle cell edit in the raw table
            %   Update the underlying Data property when user edits a cell
            indices = event.Indices;
            newData = event.NewData;
            
            % Get current table data (formatted display)
            T_display = src.Data;
            if ~istable(T_display)
                return;
            end
            
            row = indices(1);  % Row in filtered/displayed table
            col = indices(2);
            varNames = T_display.Properties.VariableNames;
            colName = varNames{col};
            
            % Get the original data structure to determine type
            if isempty(obj.Data) || ~ismember(colName, obj.Data.Properties.VariableNames)
                return;
            end
            
            % Map filtered row index to original data row index
            if ~isempty(obj.FilteredRowIndices) && row <= length(obj.FilteredRowIndices)
                originalRow = obj.FilteredRowIndices(row);
            else
                % Fallback: assume row matches (no filtering or mapping lost)
                originalRow = row;
            end
            
            originalColData = obj.Data.(colName);
            
            % Convert new value based on original column type
            if isnumeric(originalColData) && ~islogical(originalColData)
                % Numeric column - convert string input to number
                if ischar(newData) || isstring(newData) || iscell(newData)
                    if iscell(newData)
                        valStr = string(newData{1});
                    else
                        valStr = string(newData);
                    end
                    if valStr == "" || ismissing(valStr)
                        numVal = nan;
                    else
                        numVal = str2double(valStr);
                        if isnan(numVal)
                            % Invalid number - revert
                            uialert(obj.ParentFigure, ...
                                'Invalid number. Please enter a numeric value.', ...
                                'Invalid Input', 'Icon', 'warning');
                            % Revert the cell
                            T_display.(colName)(row) = event.PreviousData;
                            src.Data = T_display;
                            return;
                        end
                    end
                else
                    numVal = newData;
                end
                % Update original data at the correct row
                if originalRow <= height(obj.Data)
                    obj.Data.(colName)(originalRow) = numVal;
                end
                % Format for display
                if isnan(numVal)
                    T_display.(colName)(row) = {''};
                else
                    T_display.(colName)(row) = {sprintf('%.1f', numVal)};
                end
            elseif islogical(originalColData)
                % Logical column
                if originalRow <= height(obj.Data)
                    obj.Data.(colName)(originalRow) = logical(newData);
                end
                T_display.(colName)(row) = logical(newData);
            else
                % String/cell column
                if originalRow <= height(obj.Data)
                    obj.Data.(colName)(originalRow) = newData;
                end
                T_display.(colName)(row) = newData;
            end
            
            % Update display
            src.Data = T_display;
            
            % Refresh other displays (but don't refresh the table itself to avoid flicker)
            T_filtered = obj.getFilteredData();
            obj.updateSpongeSummary(T_filtered);
            obj.updateSlipstreamSummary(T_filtered);
            obj.updatePlots(T_filtered);
        end
        
        function updateDataFromTable(obj)
            %UPDATEDATAFROMTABLE Update Data property from current table display
            %   This is called before saving to ensure Data is up to date
            %   The Data property should already be updated via cell edit callbacks
            %   This is mainly for safety/consistency
            T_display = obj.RawTable.Data;
            if ~istable(T_display) || isempty(T_display)
                return;
            end
            
            % Convert formatted display back to numeric for all columns
            if ~isempty(obj.Data)
                obj.Data = obj.unformatTableFromDisplay(T_display, obj.Data);
            end
        end
    end
end
