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
            
            filterGrid = uigridlayout(obj.FilterPanel, [1 7]);
            % Dropdown columns are 1/3 smaller (2/3 of original size)
            % Columns: Sponge label, Sponge dropdown, Slipstream label, Slipstream dropdown, 
            %          Session label, Session dropdown, Reload button
            % Making dropdown columns smaller - using 0.5x to ensure they're actually smaller
            filterGrid.ColumnWidth = {'fit', '0.5x', 'fit', '0.5x', 'fit', '0.5x', 'fit'};
            
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
            
            % Reload button (in same row, last cell)
            obj.ReloadButton = uibutton(filterGrid, ...
                'Text', 'Reload CSV', ...
                'ButtonPushedFcn', @(btn, event) obj.onReloadButtonPushed());
            
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
                'ColumnEditable', false, ...
                'RowName', []);
            obj.RawTable.Layout.Row = 1;
            obj.RawTable.Layout.Column = 1;
            
            % NOTE: width is up to column J because the data itself only has
            % 10 columns; the table will automatically size to show them.
            obj.RawTable.ColumnWidth = 'auto';
            
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
            
            % Sponge filter
            spongeValue = obj.SpongeFilterDropDown.Value;
            if ~strcmp(spongeValue, 'All') && ismember('Sponge', T.Properties.VariableNames)
                if strcmp(spongeValue, 'NONE')
                    % rows with empty or missing sponge (if you ever add them)
                    mask = ismissing(T.Sponge) | strcmpi(strtrim(string(T.Sponge)), '');
                    T = T(mask, :);
                else
                    mask = strcmp(string(T.Sponge), spongeValue);
                    T = T(mask, :);
                end
            end
            
            % Slipstream filter
            slipValue = obj.SlipstreamFilterDropDown.Value;
            if ismember('Slipstream', T.Properties.VariableNames)
                switch slipValue
                    case 'No slipstream (0)'
                        T = T(T.Slipstream == 0, :);
                    case 'Slipstream (1)'
                        T = T(T.Slipstream == 1, :);
                    otherwise
                        % 'All' -> no extra filter
                end
            end
            
            % Session filter
            sessValue = obj.SessionFilterDropDown.Value;
            if ~strcmp(sessValue, 'All') && ismember('Session', T.Properties.VariableNames)
                T = T(strcmp(string(T.Session), sessValue), :);
            end
        end
        
        function refreshAll(obj)
            T = obj.getFilteredData();
            obj.updateRawTable(T);
            obj.updateSpongeSummary(T);
            obj.updateSlipstreamSummary(T);
            obj.updatePlots(T);
        end
        
        function updateRawTable(obj, T)
            if isempty(T)
                obj.RawTable.Data = {};
                obj.RawTable.ColumnName = {};
            else
                obj.RawTable.Data = T;
                obj.RawTable.ColumnName = T.Properties.VariableNames;
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
    end
end
