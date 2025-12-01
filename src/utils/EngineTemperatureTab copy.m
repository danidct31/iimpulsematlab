classdef EngineTemperatureTab < handle
    %ENGINETEMPERATURETAB Tab for analyzing engine temperature data
    
    properties (Access = private)
        Tab                    matlab.ui.container.Tab
        ParentFigure          matlab.ui.Figure
        CSVPath               string
        DataTable             table
        UITable               matlab.ui.control.Table
        AnalysisPanel         matlab.ui.container.Panel
        PlotAxes              matlab.ui.control.UIAxes
        StatsPanel            matlab.ui.container.Panel
        LoadButton            matlab.ui.control.Button
        SaveButton            matlab.ui.control.Button
    end
    
    methods
        function obj = EngineTemperatureTab(parentTabGroup, parentFigure, csvPath)
            %ENGINETEMPERATURETAB Constructor
            %   parentTabGroup: TabGroup to add the engine temperature tab to
            %   parentFigure: Main UIFigure for dialogs
            %   csvPath: Path to CSV file for loading
            
            obj.ParentFigure = parentFigure;
            obj.CSVPath = string(csvPath);
            
            obj.createUI(parentTabGroup);
            obj.loadData();
        end
        
        function createUI(obj, parentTabGroup)
            %CREATEUI Create all UI components for the Engine Temperature tab
            
            % Create the tab
            obj.Tab = uitab(parentTabGroup);
            obj.Tab.Title = 'Engine Temperature';
            
            % Get tab dimensions (approximate, will adjust)
            tabWidth = 1133;
            tabHeight = 608;
            
            % --- Load and Save buttons (top left, same style as ChecklistTab) ---
            buttonWidth = 100;
            buttonSpacing = 5;
            buttonHeight = 22;
            buttonY = 580;
            leftMarginButtons = 7;
            
            loadButtonX = leftMarginButtons;
            saveButtonX = leftMarginButtons + buttonWidth + buttonSpacing;
            
            % Load button
            obj.LoadButton = uibutton(obj.Tab, 'push');
            obj.LoadButton.Text = 'Load';
            obj.LoadButton.ButtonPushedFcn = @(src, event) obj.onLoadButtonPushed(src, event);
            obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
            obj.LoadButton.Visible = 'on';
            obj.LoadButton.BackgroundColor = [0.94 0.94 0.94];
            obj.LoadButton.FontColor = [0 0 0];
            
            % Save button
            obj.SaveButton = uibutton(obj.Tab, 'push');
            obj.SaveButton.Text = 'Save';
            obj.SaveButton.ButtonPushedFcn = @(src, event) obj.onSaveButtonPushed(src, event);
            obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
            obj.SaveButton.Visible = 'on';
            obj.SaveButton.BackgroundColor = [0.94 0.94 0.94];
            obj.SaveButton.FontColor = [0 0 0];
            
            % Move buttons to front
            uistack(obj.LoadButton, 'top');
            uistack(obj.SaveButton, 'top');
            
            % Create main data table (scrollable, showing columns A-J, 150 rows editable)
            obj.UITable = uitable(obj.Tab);
            obj.UITable.Position = [10 200 tabWidth - 320 350];
            obj.UITable.ColumnEditable = true; % Make editable
            
            % Create analysis panel on the right side (moved lower)
            obj.AnalysisPanel = uipanel(obj.Tab);
            obj.AnalysisPanel.Title = 'Analysis & Visualization';
            obj.AnalysisPanel.Position = [tabWidth - 300 150 290 400];
            
            % Create plot axes (larger for better visibility)
            obj.PlotAxes = uiaxes(obj.AnalysisPanel);
            obj.PlotAxes.Position = [10 200 270 180];
            obj.PlotAxes.Title.String = 'Water Temp vs Oil Temp';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            
            % Create statistics panel
            obj.StatsPanel = uipanel(obj.AnalysisPanel);
            obj.StatsPanel.Title = 'Statistics';
            obj.StatsPanel.Position = [10 10 270 180];
            
            % Add analysis buttons (arranged in a grid, moved lower)
            btnPlot = uibutton(obj.AnalysisPanel, 'push');
            btnPlot.Text = 'Water vs Oil Temp';
            btnPlot.Position = [10 160 130 25];
            btnPlot.ButtonPushedFcn = @(src, event) obj.plotWaterVsOil();
            
            btnSponge = uibutton(obj.AnalysisPanel, 'push');
            btnSponge.Text = 'Compare Sponge (L vs M)';
            btnSponge.Position = [150 160 130 25];
            btnSponge.ButtonPushedFcn = @(src, event) obj.compareSponge();
            
            btnTapes = uibutton(obj.AnalysisPanel, 'push');
            btnTapes.Text = 'Analyze Tape Effects';
            btnTapes.Position = [10 130 130 25];
            btnTapes.ButtonPushedFcn = @(src, event) obj.analyzeTapes();
            
            btnSlipstream = uibutton(obj.AnalysisPanel, 'push');
            btnSlipstream.Text = 'Slipstream Effect';
            btnSlipstream.Position = [150 130 130 25];
            btnSlipstream.ButtonPushedFcn = @(src, event) obj.analyzeSlipstream();
            
            btnAirTemp = uibutton(obj.AnalysisPanel, 'push');
            btnAirTemp.Text = 'Air Temp Effect';
            btnAirTemp.Position = [10 100 130 25];
            btnAirTemp.ButtonPushedFcn = @(src, event) obj.analyzeAirTemp();
            
            btnBellypan = uibutton(obj.AnalysisPanel, 'push');
            btnBellypan.Text = 'Bellypan Effect';
            btnBellypan.Position = [150 100 130 25];
            btnBellypan.ButtonPushedFcn = @(src, event) obj.analyzeBellypan();
        end
        
        function loadData(obj)
            %LOADDATA Load data from CSV file
            try
                if isfile(obj.CSVPath)
                    obj.DataTable = readtable(obj.CSVPath, 'TextType', 'string');
                    
                    % Get number of columns (keep all columns)
                    numCols = width(obj.DataTable);
                    
                    % Ensure we have at least 10 columns (A-J), pad if needed
                    if numCols < 10
                        % Add empty columns to reach 10
                        for i = numCols+1:10
                            obj.DataTable{:, end+1} = repmat({''}, height(obj.DataTable), 1);
                            obj.DataTable.Properties.VariableNames{end} = sprintf('Column_%d', i);
                        end
                    end
                    
                    % Take first 10 columns for display
                    displayTable = obj.DataTable(:, 1:10);
                    
                    % Ensure we have 150 rows (pad or truncate)
                    if height(displayTable) < 150
                        % Pad with empty rows matching data types
                        needed = 150 - height(displayTable);
                        emptyRows = table();
                        for i = 1:width(displayTable)
                            colName = displayTable.Properties.VariableNames{i};
                            colData = displayTable{:, i};
                            
                            % Determine data type
                            if isnumeric(colData) || islogical(colData)
                                emptyRows{:, colName} = NaN(needed, 1);
                            elseif iscategorical(colData)
                                emptyRows{:, colName} = categorical(repmat({''}, needed, 1));
                            else
                                emptyRows{:, colName} = strings(needed, 1);
                            end
                        end
                        displayTable = [displayTable; emptyRows];
                    elseif height(displayTable) > 150
                        % Truncate to 150 rows
                        displayTable = displayTable(1:150, :);
                    end
                    
                    obj.UITable.Data = displayTable;
                    obj.UITable.ColumnName = displayTable.Properties.VariableNames;
                    
                    % Auto-size columns
                    obj.UITable.ColumnWidth = repmat({'auto'}, 1, width(displayTable));
                    
                    % Update statistics
                    obj.updateStatistics();
                else
                    % File doesn't exist - create empty table with 150 rows
                    obj.createEmptyTable();
                end
            catch ME
                uialert(obj.ParentFigure, ...
                    "Failed to load CSV: " + ME.message, ...
                    'Load Error', 'Icon', 'error');
                % Create empty table on error
                obj.createEmptyTable();
            end
        end
        
        function createEmptyTable(obj)
            %CREATEEMPTYTABLE Create an empty table with 150 rows and 10 columns
            % Use column names from CSV header if available, otherwise generic names
            columnNames = {'Session', 'Air temp', 'Water rad tapes', 'Oil rad tapes', ...
                          'Bellypan tape', 'Sponge', 'Water temp', 'Oil temp', ...
                          'Slipstream', 'Time'};
            
            % Create table with appropriate data types
            % Column 1: Session (string)
            % Column 2: Air temp (numeric)
            % Column 3: Water rad tapes (numeric)
            % Column 4: Oil rad tapes (numeric)
            % Column 5: Bellypan tape (numeric)
            % Column 6: Sponge (string)
            % Column 7: Water temp (numeric)
            % Column 8: Oil temp (numeric)
            % Column 9: Slipstream (numeric)
            % Column 10: Time (numeric)
            
            emptyTable = table(...
                strings(150, 1), ...      % Session
                NaN(150, 1), ...          % Air temp
                NaN(150, 1), ...          % Water rad tapes
                NaN(150, 1), ...          % Oil rad tapes
                NaN(150, 1), ...          % Bellypan tape
                strings(150, 1), ...      % Sponge
                NaN(150, 1), ...          % Water temp
                NaN(150, 1), ...          % Oil temp
                NaN(150, 1), ...          % Slipstream
                NaN(150, 1), ...          % Time
                'VariableNames', columnNames);
            
            obj.UITable.Data = emptyTable;
            obj.UITable.ColumnName = columnNames;
            obj.UITable.ColumnWidth = repmat({'auto'}, 1, 10);
            
            % Initialize DataTable
            obj.DataTable = emptyTable;
        end
        
        function onLoadButtonPushed(obj, ~, ~)
            %ONLOADBUTTONPUSHED Load data from CSV
            obj.loadData();
        end
        
        function onSaveButtonPushed(obj, ~, ~)
            %ONSAVEBUTTONPUSHED Save current table data to CSV
            try
                % Get data from UI table
                tableData = obj.UITable.Data;
                
                % Ensure it's a table
                if ~istable(tableData)
                    % Convert cell array to table
                    tableData = cell2table(tableData, 'VariableNames', obj.UITable.ColumnName);
                end
                
                % Remove completely empty rows (all cells empty/NaN/empty string)
                if height(tableData) > 0
                    emptyRows = false(height(tableData), 1);
                    for i = 1:height(tableData)
                        rowEmpty = true;
                        for j = 1:width(tableData)
                            val = tableData{i, j};
                            if isnumeric(val) || islogical(val)
                                if ~isnan(val)
                                    rowEmpty = false;
                                    break;
                                end
                            elseif isstring(val) || ischar(val)
                                if ~isempty(strtrim(string(val)))
                                    rowEmpty = false;
                                    break;
                                end
                            else
                                if ~isempty(val)
                                    rowEmpty = false;
                                    break;
                                end
                            end
                        end
                        emptyRows(i) = rowEmpty;
                    end
                    tableData = tableData(~emptyRows, :);
                end
                
                % Write to CSV
                writetable(tableData, obj.CSVPath);
                
                % Update internal DataTable (keep all 150 rows for UI)
                obj.DataTable = obj.UITable.Data;
                
                % Update statistics
                obj.updateStatistics();
                
                % Success (silent, like ChecklistTab)
            catch ME
                uialert(obj.ParentFigure, ...
                    "Save failed: " + ME.message, ...
                    'Save Error', 'Icon', 'error');
            end
        end
        
        function updateStatistics(obj)
            %UPDATESTATISTICS Update the statistics panel
            if isempty(obj.DataTable) || height(obj.DataTable) == 0
                return;
            end
            
            % Clear previous statistics
            delete(obj.StatsPanel.Children);
            
            % Calculate statistics
            stats = {};
            
            % Water temp stats
            if ismember('Water temp', obj.DataTable.Properties.VariableNames)
                waterTemps = obj.DataTable{'Water temp'};
                waterTemps = waterTemps(~isnan(waterTemps));
                if ~isempty(waterTemps)
                    stats{end+1} = sprintf('Water Temp: %.1f - %.1f °C (avg: %.1f)', ...
                        min(waterTemps), max(waterTemps), mean(waterTemps));
                end
            end
            
            % Oil temp stats
            if ismember('Oil temp', obj.DataTable.Properties.VariableNames)
                oilTemps = obj.DataTable{'Oil temp'};
                oilTemps = oilTemps(~isnan(oilTemps));
                if ~isempty(oilTemps)
                    stats{end+1} = sprintf('Oil Temp: %.1f - %.1f °C (avg: %.1f)', ...
                        min(oilTemps), max(oilTemps), mean(oilTemps));
                end
            end
            
            % Sponge distribution
            if ismember('Sponge', obj.DataTable.Properties.VariableNames)
                spongeTypes = categorical(obj.DataTable.Sponge);
                uniqueSponges = categories(spongeTypes);
                for i = 1:length(uniqueSponges)
                    count = sum(spongeTypes == uniqueSponges{i});
                    stats{end+1} = sprintf('Sponge %s: %d sessions', uniqueSponges{i}, count);
                end
            end
            
            % Display statistics as labels
            yPos = 140;
            for i = 1:length(stats)
                lbl = uilabel(obj.StatsPanel);
                lbl.Text = stats{i};
                lbl.Position = [10 yPos 260 20];
                lbl.FontSize = 10;
                yPos = yPos - 25;
            end
        end
        
        function plotWaterVsOil(obj)
            %PLOTWATERVSOIL Plot water temperature vs oil temperature
            if isempty(obj.DataTable) || ...
               ~ismember('Water temp', obj.DataTable.Properties.VariableNames) || ...
               ~ismember('Oil temp', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Data not available for plotting', ...
                    'Plot Error', 'Icon', 'error');
                return;
            end
            
            waterTemps = obj.DataTable{'Water temp'};
            oilTemps = obj.DataTable{'Oil temp'};
            
            % Remove NaN values
            validIdx = ~isnan(waterTemps) & ~isnan(oilTemps);
            waterTemps = waterTemps(validIdx);
            oilTemps = oilTemps(validIdx);
            
            if isempty(waterTemps)
                uialert(obj.ParentFigure, 'No valid data points for plotting', ...
                    'Plot Error', 'Icon', 'error');
                return;
            end
            
            % Plot with color coding by Sponge if available
            cla(obj.PlotAxes);
            hold(obj.PlotAxes, 'on');
            
            if ismember('Sponge', obj.DataTable.Properties.VariableNames)
                spongeTypes = categorical(obj.DataTable.Sponge(validIdx));
                uniqueSponges = categories(spongeTypes);
                colors = lines(length(uniqueSponges));
                
                for i = 1:length(uniqueSponges)
                    idx = spongeTypes == uniqueSponges{i};
                    scatter(obj.PlotAxes, waterTemps(idx), oilTemps(idx), ...
                        50, colors(i,:), 'filled', 'DisplayName', char(uniqueSponges{i}));
                end
                legend(obj.PlotAxes, 'Location', 'best');
            else
                scatter(obj.PlotAxes, waterTemps, oilTemps, 50, 'filled');
            end
            
            hold(obj.PlotAxes, 'off');
            obj.PlotAxes.Title.String = 'Water Temp vs Oil Temp';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            grid(obj.PlotAxes, 'on');
        end
        
        function compareSponge(obj)
            %COMPARESPONGE Compare temperature differences between L and M sponge
            if isempty(obj.DataTable) || ...
               ~ismember('Sponge', obj.DataTable.Properties.VariableNames) || ...
               ~ismember('Water temp', obj.DataTable.Properties.VariableNames) || ...
               ~ismember('Oil temp', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Data not available for comparison', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Filter data by sponge type
            L_idx = obj.DataTable.Sponge == 'L';
            M_idx = obj.DataTable.Sponge == 'M';
            
            if ~any(L_idx) || ~any(M_idx)
                uialert(obj.ParentFigure, 'Need both L and M sponge data for comparison', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Calculate statistics
            L_water = obj.DataTable{L_idx, 'Water temp'};
            L_oil = obj.DataTable{L_idx, 'Oil temp'};
            M_water = obj.DataTable{M_idx, 'Water temp'};
            M_oil = obj.DataTable{M_idx, 'Oil temp'};
            
            % Remove NaN
            L_water = L_water(~isnan(L_water));
            L_oil = L_oil(~isnan(L_oil));
            M_water = M_water(~isnan(M_water));
            M_oil = M_oil(~isnan(M_oil));
            
            % Create comparison plot
            cla(obj.PlotAxes);
            hold(obj.PlotAxes, 'on');
            
            scatter(obj.PlotAxes, L_water, L_oil, 50, [0 0.5 1], 'filled', 'DisplayName', 'Sponge L');
            scatter(obj.PlotAxes, M_water, M_oil, 50, [1 0.5 0], 'filled', 'DisplayName', 'Sponge M');
            
            hold(obj.PlotAxes, 'off');
            obj.PlotAxes.Title.String = 'Sponge Comparison: L vs M';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            legend(obj.PlotAxes, 'Location', 'best');
            grid(obj.PlotAxes, 'on');
            
            % Display differences
            msg = sprintf(['Sponge Comparison:\n\n' ...
                'L Sponge:\n' ...
                '  Water: %.1f°C avg (%.1f - %.1f)\n' ...
                '  Oil: %.1f°C avg (%.1f - %.1f)\n\n' ...
                'M Sponge:\n' ...
                '  Water: %.1f°C avg (%.1f - %.1f)\n' ...
                '  Oil: %.1f°C avg (%.1f - %.1f)\n\n' ...
                'Difference (L - M):\n' ...
                '  Water: %.1f°C\n' ...
                '  Oil: %.1f°C'], ...
                mean(L_water), min(L_water), max(L_water), ...
                mean(L_oil), min(L_oil), max(L_oil), ...
                mean(M_water), min(M_water), max(M_water), ...
                mean(M_oil), min(M_oil), max(M_oil), ...
                mean(L_water) - mean(M_water), ...
                mean(L_oil) - mean(M_oil));
            
            uialert(obj.ParentFigure, msg, 'Sponge Comparison', 'Icon', 'none');
        end
        
        function analyzeTapes(obj)
            %ANALYZETAPES Analyze the effect of radiator tapes on temperatures
            if isempty(obj.DataTable) || ...
               ~ismember('Water rad tapes', obj.DataTable.Properties.VariableNames) || ...
               ~ismember('Oil rad tapes', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Tape data not available', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Create scatter plot with tape count as color
            waterTemps = obj.DataTable{'Water temp'};
            oilTemps = obj.DataTable{'Oil temp'};
            waterTapes = obj.DataTable{'Water rad tapes'};
            oilTapes = obj.DataTable{'Oil rad tapes'};
            
            validIdx = ~isnan(waterTemps) & ~isnan(oilTemps) & ...
                       ~isnan(waterTapes) & ~isnan(oilTapes);
            
            if ~any(validIdx)
                uialert(obj.ParentFigure, 'No valid data for tape analysis', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Plot with total tape count as color
            totalTapes = waterTapes(validIdx) + oilTapes(validIdx);
            
            cla(obj.PlotAxes);
            scatter(obj.PlotAxes, waterTemps(validIdx), oilTemps(validIdx), ...
                50, totalTapes, 'filled');
            colorbar(obj.PlotAxes);
            obj.PlotAxes.Title.String = 'Temperature vs Total Tapes (Water + Oil)';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            grid(obj.PlotAxes, 'on');
        end
        
        function analyzeSlipstream(obj)
            %ANALYZESLIPSTREAM Analyze the effect of slipstream on temperatures
            if isempty(obj.DataTable) || ...
               ~ismember('Slipstream', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Slipstream data not available', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Compare temperatures with and without slipstream
            noSlip = obj.DataTable.Slipstream == 0;
            withSlip = obj.DataTable.Slipstream == 1;
            
            if ~any(noSlip) || ~any(withSlip)
                uialert(obj.ParentFigure, 'Need both slipstream conditions for comparison', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            waterTemps = obj.DataTable{'Water temp'};
            oilTemps = obj.DataTable{'Oil temp'};
            
            noSlip_water = waterTemps(noSlip & ~isnan(waterTemps));
            noSlip_oil = oilTemps(noSlip & ~isnan(oilTemps));
            withSlip_water = waterTemps(withSlip & ~isnan(waterTemps));
            withSlip_oil = oilTemps(withSlip & ~isnan(oilTemps));
            
            % Plot comparison
            cla(obj.PlotAxes);
            hold(obj.PlotAxes, 'on');
            
            scatter(obj.PlotAxes, noSlip_water, noSlip_oil, 50, [0 0.8 0], ...
                'filled', 'DisplayName', 'No Slipstream');
            scatter(obj.PlotAxes, withSlip_water, withSlip_oil, 50, [0.8 0 0], ...
                'filled', 'DisplayName', 'With Slipstream');
            
            hold(obj.PlotAxes, 'off');
            obj.PlotAxes.Title.String = 'Slipstream Effect on Temperatures';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            legend(obj.PlotAxes, 'Location', 'best');
            grid(obj.PlotAxes, 'on');
            
            % Display statistics
            msg = sprintf(['Slipstream Analysis:\n\n' ...
                'No Slipstream:\n' ...
                '  Water: %.1f°C avg\n' ...
                '  Oil: %.1f°C avg\n\n' ...
                'With Slipstream:\n' ...
                '  Water: %.1f°C avg\n' ...
                '  Oil: %.1f°C avg\n\n' ...
                'Temperature Difference:\n' ...
                '  Water: %.1f°C\n' ...
                '  Oil: %.1f°C'], ...
                mean(noSlip_water), mean(noSlip_oil), ...
                mean(withSlip_water), mean(withSlip_oil), ...
                mean(noSlip_water) - mean(withSlip_water), ...
                mean(noSlip_oil) - mean(withSlip_oil));
            
            uialert(obj.ParentFigure, msg, 'Slipstream Analysis', 'Icon', 'none');
        end
        
        function analyzeAirTemp(obj)
            %ANALYZEAIRTEMP Analyze the effect of air temperature on engine temperatures
            if isempty(obj.DataTable) || ...
               ~ismember('Air temp', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Air temperature data not available', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            airTemps = obj.DataTable{'Air temp'};
            waterTemps = obj.DataTable{'Water temp'};
            oilTemps = obj.DataTable{'Oil temp'};
            
            validIdx = ~isnan(airTemps) & ~isnan(waterTemps) & ~isnan(oilTemps);
            
            if ~any(validIdx)
                uialert(obj.ParentFigure, 'No valid data for air temperature analysis', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Plot water temp vs air temp
            cla(obj.PlotAxes);
            yyaxis(obj.PlotAxes, 'left');
            scatter(obj.PlotAxes, airTemps(validIdx), waterTemps(validIdx), ...
                50, 'filled', 'DisplayName', 'Water Temp');
            obj.PlotAxes.YLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YColor = [0 0.5 1];
            
            yyaxis(obj.PlotAxes, 'right');
            scatter(obj.PlotAxes, airTemps(validIdx), oilTemps(validIdx), ...
                50, 'filled', 'DisplayName', 'Oil Temp');
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            obj.PlotAxes.YColor = [1 0.5 0];
            
            obj.PlotAxes.Title.String = 'Engine Temperatures vs Air Temperature';
            obj.PlotAxes.XLabel.String = 'Air Temperature (°C)';
            grid(obj.PlotAxes, 'on');
            legend(obj.PlotAxes, 'Location', 'best');
        end
        
        function analyzeBellypan(obj)
            %ANALYZEBELLYPAN Analyze the effect of bellypan tape on oil temperature
            if isempty(obj.DataTable) || ...
               ~ismember('Bellypan tape', obj.DataTable.Properties.VariableNames) || ...
               ~ismember('Oil temp', obj.DataTable.Properties.VariableNames)
                uialert(obj.ParentFigure, 'Bellypan data not available', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            % Compare oil temperatures with and without bellypan tape
            bellypanOn = obj.DataTable{'Bellypan tape'} == 1;
            bellypanOff = obj.DataTable{'Bellypan tape'} == 0;
            
            if ~any(bellypanOn) || ~any(bellypanOff)
                uialert(obj.ParentFigure, 'Need both bellypan conditions for comparison', ...
                    'Analysis Error', 'Icon', 'error');
                return;
            end
            
            oilTemps = obj.DataTable{'Oil temp'};
            waterTemps = obj.DataTable{'Water temp'};
            
            on_oil = oilTemps(bellypanOn & ~isnan(oilTemps));
            off_oil = oilTemps(bellypanOff & ~isnan(oilTemps));
            on_water = waterTemps(bellypanOn & ~isnan(waterTemps));
            off_water = waterTemps(bellypanOff & ~isnan(waterTemps));
            
            % Plot comparison
            cla(obj.PlotAxes);
            hold(obj.PlotAxes, 'on');
            
            scatter(obj.PlotAxes, on_water, on_oil, 50, [0.8 0 0], ...
                'filled', 'DisplayName', 'Bellypan ON');
            scatter(obj.PlotAxes, off_water, off_oil, 50, [0 0 0.8], ...
                'filled', 'DisplayName', 'Bellypan OFF');
            
            hold(obj.PlotAxes, 'off');
            obj.PlotAxes.Title.String = 'Bellypan Tape Effect on Oil Temperature';
            obj.PlotAxes.XLabel.String = 'Water Temp (°C)';
            obj.PlotAxes.YLabel.String = 'Oil Temp (°C)';
            legend(obj.PlotAxes, 'Location', 'best');
            grid(obj.PlotAxes, 'on');
            
            % Display statistics
            msg = sprintf(['Bellypan Analysis:\n\n' ...
                'Bellypan ON:\n' ...
                '  Oil: %.1f°C avg (%.1f - %.1f)\n\n' ...
                'Bellypan OFF:\n' ...
                '  Oil: %.1f°C avg (%.1f - %.1f)\n\n' ...
                'Temperature Difference:\n' ...
                '  Oil: %.1f°C'], ...
                mean(on_oil), min(on_oil), max(on_oil), ...
                mean(off_oil), min(off_oil), max(off_oil), ...
                mean(on_oil) - mean(off_oil));
            
            uialert(obj.ParentFigure, msg, 'Bellypan Analysis', 'Icon', 'none');
        end
    end
end

