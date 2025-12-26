classdef RythmTab < handle
    % RythmTab
    % Tab to display rider data from motogp_analysis_riders.csv
    
    properties
        ParentTabGroup
        ParentFigure
        Tab
        
        MainGrid
        RidersTable
        Rider1DropDown
        Rider2DropDown
        ClearButton
        RidersTab
        NestedTabGroup
        
        % Laps tables
        LapsTable1
        LapsTable2
        LapsTable1DropDown
        LapsTable2DropDown
        LapsSummaryTable1
        LapsSummaryTable2
        
        % Sectors table
        SectorsTable
        SectorsSummaryTable
        Sector1DropDown
        Sector2DropDown
        SectorsClearButton
        
        % Speeds table
        SpeedsTable
        SpeedsAxes               % Axes for speeds graph
        
        % Data
        CsvPath
        Data table
        TableData table
        LapsData table
        SectorsData table
    end
    
    methods
        function obj = RythmTab(tabGroup, parentFigure, csvPath)
            obj.ParentTabGroup = tabGroup;
            obj.ParentFigure   = parentFigure;
            obj.CsvPath        = csvPath;
            
            obj.createUI();
            obj.loadData();
        end
    end
    
    methods (Access = private)
        
        function createUI(obj)
            % Create tab
            obj.Tab = uitab(obj.ParentTabGroup);
            obj.Tab.Title = 'Rythm';
            
            % Try to set tab background to dark grey
            try
                obj.Tab.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be directly supported
            end
            
            % Create nested tab group inside RythmTab
            nestedTabGroup = uitabgroup(obj.Tab);
            nestedTabGroup.Position = [1 1 1133 632];
            obj.NestedTabGroup = nestedTabGroup; % Store reference
            
            % Add callback to scroll to top when Riders tab is selected
            nestedTabGroup.SelectionChangedFcn = @(src, event) obj.onTabSelectionChanged(src, event);
            
            % Create first tab: Main Riders Table
            ridersTab = uitab(nestedTabGroup);
            ridersTab.Title = 'Riders';
            ridersTab.BackgroundColor = [0.3 0.3 0.3];
            obj.RidersTab = ridersTab; % Store reference
            
            % Create grid for riders tab
            ridersGrid = uigridlayout(ridersTab, [2 1]);
            ridersGrid.RowHeight = {'fit', '1x'};
            ridersGrid.ColumnWidth = {'1x'};
            ridersGrid.Padding = [10 10 10 10];
            ridersGrid.BackgroundColor = [0.3 0.3 0.3];
            
            % Create combo boxes panel
            comboPanel = uipanel(ridersGrid);
            comboPanel.Layout.Row = 1;
            comboPanel.Layout.Column = 1;
            comboPanel.BackgroundColor = [0.3 0.3 0.3];
            
            comboGrid = uigridlayout(comboPanel, [1 5]);
            comboGrid.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit'};
            comboGrid.Padding = [5 5 5 5];
            
            % First rider dropdown
            uilabel(comboGrid, 'Text', 'Rider 1:', 'FontColor', [0 0 0]);
            obj.Rider1DropDown = uidropdown(comboGrid, ...
                'Items', {''}, ...
                'Value', '', ...
                'ValueChangedFcn', @(dd, event) obj.onRider1Changed());
            obj.Rider1DropDown.Layout.Column = 2;
            
            % Second rider dropdown
            uilabel(comboGrid, 'Text', 'Rider 2:', 'FontColor', [0 0 0]);
            obj.Rider2DropDown = uidropdown(comboGrid, ...
                'Items', {''}, ...
                'Value', '', ...
                'ValueChangedFcn', @(dd, event) obj.onRider2Changed());
            obj.Rider2DropDown.Layout.Column = 4;
            
            % Clear button
            obj.ClearButton = uibutton(comboGrid, ...
                'Text', 'Clear', ...
                'ButtonPushedFcn', @(btn, event) obj.onClearButtonPushed());
            obj.ClearButton.Layout.Column = 5;
            
            % Create table directly in grid (no scrollable panel)
            % Table will automatically fit available space
            obj.RidersTable = uitable(ridersGrid);
            obj.RidersTable.Layout.Row = 2;
            obj.RidersTable.Layout.Column = 1;
            obj.RidersTable.ColumnEditable = false;
            obj.RidersTable.RowName = [];
            obj.RidersTable.ColumnWidth = 'auto';
            
            % Apply center alignment style to all cells
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.RidersTable, centerStyle);
            
            % Create second tab: Laps Tables
            lapsTab = uitab(nestedTabGroup);
            lapsTab.Title = 'Laps';
            lapsTab.BackgroundColor = [0.3 0.3 0.3];
            
            % Create grid for laps tab (1 row, 2 columns for side-by-side layout)
            lapsGrid = uigridlayout(lapsTab, [1 2]);
            lapsGrid.RowHeight = {'1x'};
            lapsGrid.ColumnWidth = {'1x', '1x'};
            lapsGrid.Padding = [10 10 10 10];
            lapsGrid.BackgroundColor = [0.3 0.3 0.3];
            obj.MainGrid = lapsGrid; % Store for createLapsTableSection
            
            % Create first laps table section (left column)
            obj.createLapsTableSection(1, 1, 1);
            
            % Create second laps table section (right column)
            obj.createLapsTableSection(1, 2, 2);
            
            % Create third tab: Sectors Table
            sectorsTab = uitab(nestedTabGroup);
            sectorsTab.Title = 'Sectors';
            sectorsTab.BackgroundColor = [0.3 0.3 0.3];
            
            % Create grid for sectors tab
            sectorsGrid = uigridlayout(sectorsTab, [2 2]);
            sectorsGrid.RowHeight = {'fit', '1x'};
            sectorsGrid.ColumnWidth = {'2x', '1x'};
            sectorsGrid.Padding = [10 10 10 10];
            sectorsGrid.BackgroundColor = [0.3 0.3 0.3];
            
            % Create combo boxes panel (spanning both columns)
            sectorsComboPanel = uipanel(sectorsGrid);
            sectorsComboPanel.Layout.Row = 1;
            sectorsComboPanel.Layout.Column = [1 2];
            sectorsComboPanel.BackgroundColor = [0.3 0.3 0.3];
            
            sectorsComboGrid = uigridlayout(sectorsComboPanel, [1 5]);
            sectorsComboGrid.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit'};
            sectorsComboGrid.Padding = [5 5 5 5];
            
            % First rider dropdown
            uilabel(sectorsComboGrid, 'Text', 'Rider 1:', 'FontColor', [0 0 0]);
            obj.Sector1DropDown = uidropdown(sectorsComboGrid, ...
                'Items', {''}, ...
                'Value', '', ...
                'ValueChangedFcn', @(dd, event) obj.onSector1Changed());
            obj.Sector1DropDown.Layout.Column = 2;
            
            % Second rider dropdown
            uilabel(sectorsComboGrid, 'Text', 'Rider 2:', 'FontColor', [0 0 0]);
            obj.Sector2DropDown = uidropdown(sectorsComboGrid, ...
                'Items', {''}, ...
                'Value', '', ...
                'ValueChangedFcn', @(dd, event) obj.onSector2Changed());
            obj.Sector2DropDown.Layout.Column = 4;
            
            % Clear button
            obj.SectorsClearButton = uibutton(sectorsComboGrid, ...
                'Text', 'Clear', ...
                'ButtonPushedFcn', @(btn, event) obj.onSectorsClearButtonPushed());
            obj.SectorsClearButton.Layout.Column = 5;
            
            % Create main sectors table (left, 2/3 width)
            obj.SectorsTable = uitable(sectorsGrid);
            obj.SectorsTable.Layout.Row = 2;
            obj.SectorsTable.Layout.Column = 1;
            obj.SectorsTable.ColumnEditable = false;
            obj.SectorsTable.RowName = [];
            obj.SectorsTable.ColumnWidth = 'auto';
            obj.SectorsTable.Data = {};
            obj.SectorsTable.ColumnName = {};
            % Remove ColumnFormat if it exists to avoid warnings with table Data
            if isprop(obj.SectorsTable, 'ColumnFormat')
                obj.SectorsTable.ColumnFormat = {};
            end
            
            % Apply center alignment style to all cells
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.SectorsTable, centerStyle);
            
            % Create summary table (right, 1/3 width)
            obj.SectorsSummaryTable = uitable(sectorsGrid);
            obj.SectorsSummaryTable.Layout.Row = 2;
            obj.SectorsSummaryTable.Layout.Column = 2;
            obj.SectorsSummaryTable.ColumnEditable = false;
            obj.SectorsSummaryTable.RowName = [];
            obj.SectorsSummaryTable.ColumnWidth = 'auto';
            obj.SectorsSummaryTable.Data = {};
            obj.SectorsSummaryTable.ColumnName = {'Rider_Name', 'Position', 'Ideal_Laptime', 'Best_Laptime'};
            % Remove ColumnFormat if it exists to avoid warnings with table Data
            if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                obj.SectorsSummaryTable.ColumnFormat = {};
            end
            
            % Apply center alignment style to summary table
            centerStyleSummary = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.SectorsSummaryTable, centerStyleSummary);
            
            % Create fourth tab: Speeds Table
            speedsTab = uitab(nestedTabGroup);
            speedsTab.Title = 'Speeds';
            speedsTab.BackgroundColor = [0.3 0.3 0.3];
            
            % Create grid for speeds tab (table on left, graph on right)
            speedsGrid = uigridlayout(speedsTab, [1 2]);
            speedsGrid.RowHeight = {'1x'};
            speedsGrid.ColumnWidth = {'2x', '1x'};
            speedsGrid.Padding = [10 10 10 10];
            speedsGrid.BackgroundColor = [0.3 0.3 0.3];
            
            % Create speeds table
            obj.SpeedsTable = uitable(speedsGrid);
            obj.SpeedsTable.Layout.Row = 1;
            obj.SpeedsTable.Layout.Column = 1;
            obj.SpeedsTable.ColumnEditable = false;
            obj.SpeedsTable.RowName = [];
            obj.SpeedsTable.ColumnWidth = 'auto';
            obj.SpeedsTable.Data = {};
            obj.SpeedsTable.ColumnName = {};
            % Remove ColumnFormat if it exists to avoid warnings with table Data
            if isprop(obj.SpeedsTable, 'ColumnFormat')
                obj.SpeedsTable.ColumnFormat = {};
            end
            
            % Apply center alignment style to all cells
            centerStyleSpeeds = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.SpeedsTable, centerStyleSpeeds);
            
            % Create axes for speeds graph
            obj.SpeedsAxes = uiaxes(speedsGrid);
            obj.SpeedsAxes.Layout.Row = 1;
            obj.SpeedsAxes.Layout.Column = 2;
            obj.SpeedsAxes.BackgroundColor = [1 1 1];
            obj.SpeedsAxes.XColor = [1 1 1];
            obj.SpeedsAxes.YColor = [1 1 1];
            obj.SpeedsAxes.Color = [0.3 0.3 0.3];
            obj.SpeedsAxes.GridColor = [0.5 0.5 0.5];
            obj.SpeedsAxes.XGrid = 'on';
            obj.SpeedsAxes.YGrid = 'on';
        end
        
        function createLapsTableSection(obj, rowNum, colNum, tableNum)
            %CREATELAPSTABLESECTION Create a laps table section with combo box
            % Create panel for this table section
            tablePanel = uipanel(obj.MainGrid);
            tablePanel.Layout.Row = rowNum;
            tablePanel.Layout.Column = colNum;
            tablePanel.BackgroundColor = [0.3 0.3 0.3];
            
            % Create grid for combo box, table, and summary table
            % Summary table height: single data row (~25px) + headers (~25px) = ~50px
            % Main table gets remaining space
            sectionGrid = uigridlayout(tablePanel, [3 1]);
            sectionGrid.RowHeight = {'fit', '1x', 80};  % Main table uses remaining space, summary is fixed at 80px
            sectionGrid.ColumnWidth = {'1x'};
            sectionGrid.Padding = [5 5 5 5];
            
            % Combo box panel
            comboPanel = uipanel(sectionGrid);
            comboPanel.Layout.Row = 1;
            comboPanel.Layout.Column = 1;
            comboPanel.BackgroundColor = [0.3 0.3 0.3];
            
            comboGrid = uigridlayout(comboPanel, [1 2]);
            comboGrid.ColumnWidth = {'fit', '1x'};
            comboGrid.Padding = [5 5 5 5];
            
            % Label and dropdown
            uilabel(comboGrid, 'Text', sprintf('Rider %d:', tableNum), 'FontColor', [0 0 0]);
            if tableNum == 1
                obj.LapsTable1DropDown = uidropdown(comboGrid, ...
                    'Items', {''}, ...
                    'Value', '', ...
                    'ValueChangedFcn', @(dd, event) obj.onLapsTable1Changed());
                obj.LapsTable1DropDown.Layout.Column = 2;
            else
                obj.LapsTable2DropDown = uidropdown(comboGrid, ...
                    'Items', {''}, ...
                    'Value', '', ...
                    'ValueChangedFcn', @(dd, event) obj.onLapsTable2Changed());
                obj.LapsTable2DropDown.Layout.Column = 2;
            end
            
            % Create main laps table directly in grid (no scrollable panel)
            % Table will automatically fit available space and handle its own scrolling
            if tableNum == 1
                obj.LapsTable1 = uitable(sectionGrid);
                obj.LapsTable1.Layout.Row = 2;
                obj.LapsTable1.Layout.Column = 1;
                obj.LapsTable1.ColumnEditable = false;
                obj.LapsTable1.RowName = [];
                obj.LapsTable1.ColumnWidth = 'auto'; % Will be set dynamically when data loads
                obj.LapsTable1.Data = {};
                obj.LapsTable1.ColumnName = {};
            else
                obj.LapsTable2 = uitable(sectionGrid);
                obj.LapsTable2.Layout.Row = 2;
                obj.LapsTable2.Layout.Column = 1;
                obj.LapsTable2.ColumnEditable = false;
                obj.LapsTable2.RowName = [];
                obj.LapsTable2.ColumnWidth = 'auto'; % Will be set dynamically when data loads
                obj.LapsTable2.Data = {};
                obj.LapsTable2.ColumnName = {};
            end
            
            % Summary table panel (1/3 height)
            summaryPanel = uipanel(sectionGrid);
            summaryPanel.Layout.Row = 3;
            summaryPanel.Layout.Column = 1;
            summaryPanel.BackgroundColor = [0.3 0.3 0.3];
            
            % Create summary table (will be positioned to fill panel after layout)
            if tableNum == 1
                obj.LapsSummaryTable1 = uitable(summaryPanel);
                obj.LapsSummaryTable1.Position = [1 1 500 100]; % Temporary, will be updated
                obj.LapsSummaryTable1.ColumnEditable = false;
                obj.LapsSummaryTable1.RowName = [];
                obj.LapsSummaryTable1.ColumnWidth = 'auto';
                obj.LapsSummaryTable1.Data = {};
                obj.LapsSummaryTable1.ColumnName = {};
            else
                obj.LapsSummaryTable2 = uitable(summaryPanel);
                obj.LapsSummaryTable2.Position = [1 1 500 100]; % Temporary, will be updated
                obj.LapsSummaryTable2.ColumnEditable = false;
                obj.LapsSummaryTable2.RowName = [];
                obj.LapsSummaryTable2.ColumnWidth = 'auto';
                obj.LapsSummaryTable2.Data = {};
                obj.LapsSummaryTable2.ColumnName = {};
            end
            
            % Set AutoResizeChildren to 'off' so SizeChangedFcn works
            summaryPanel.AutoResizeChildren = 'off';
            % Use SizeChangedFcn to update table position when panel resizes
            summaryPanel.SizeChangedFcn = @(src, event) obj.resizeSummaryTable(summaryPanel, tableNum);
            % Force initial resize after layout is complete
            drawnow;
            obj.resizeSummaryTable(summaryPanel, tableNum);
        end
        
        function loadData(obj)
            %LOADDATA Load data from motogp_analysis_riders.csv and display in table
            if isfile(obj.CsvPath)
                try
                    T = readtable(obj.CsvPath);
                    obj.Data = T;
                    
                    % Load laps CSV
                    [csvDir, ~, ~] = fileparts(obj.CsvPath);
                    lapsCsvPath = fullfile(csvDir, 'motogp_analysis_laps.csv');
                    if isfile(lapsCsvPath)
                        obj.LapsData = readtable(lapsCsvPath);
                    else
                        obj.LapsData = table();
                    end
                    
                    % Load sectors CSV
                    sectorsCsvPath = fullfile(csvDir, 'motogp_analysis_sectors.csv');
                    if isfile(sectorsCsvPath)
                        obj.SectorsData = readtable(sectorsCsvPath);
                    else
                        obj.SectorsData = table();
                    end
                    
                    obj.updateTable();
                    obj.updateComboBoxes();
                    obj.updateSectorsTable();
                    obj.updateSpeedsTable();
                    
                    % No longer need to scroll - table is directly in grid layout (no scrollable panel)
                catch ME
                    warning('RythmTab:ReadError', ...
                        'Error reading %s: %s', obj.CsvPath, ME.message);
                    obj.RidersTable.Data = {};
                    obj.RidersTable.ColumnName = {};
                end
            else
                warning('RythmTab:CSVNotFound', ...
                    'CSV file not found at: %s', obj.CsvPath);
                obj.RidersTable.Data = {};
                obj.RidersTable.ColumnName = {};
            end
        end
        
        function updateTable(obj)
            %UPDATETABLE Update the table with data in the specified column order
            if isempty(obj.Data)
                obj.RidersTable.Data = {};
                obj.RidersTable.ColumnName = {};
                return;
            end
            
            % Column order: I, H (as "Number"), C, J, L, B, A, F, N, D, E
            % Mapping from CSV columns:
            % A = best_lap_time (column 1)
            % B = bike (column 2)
            % C = country (column 3)
            % D = gap_to_first (column 4)
            % E = gap_to_previous (column 5)
            % F = lap_number (column 6)
            % G = name (column 7)
            % H = number (column 8)
            % I = position (column 9)
            % J = rider_name (column 10)
            % K = rider_number (column 11)
            % L = team (column 12)
            % M = top_speed (column 13)
            % N = total_laps (column 14)
            
            varNames = obj.Data.Properties.VariableNames;
            
            % Create ordered column list
            orderedCols = {};
            colNames = {};
            
            % Column I (position) - first
            if length(varNames) >= 9
                orderedCols{end+1} = varNames{9}; % position
                colNames{end+1} = varNames{9};
            end
            
            % Column H (number) - as "Number"
            if length(varNames) >= 8
                orderedCols{end+1} = varNames{8}; % number
                colNames{end+1} = 'Number';
            end
            
            % Column C (country)
            if length(varNames) >= 3
                orderedCols{end+1} = varNames{3}; % country
                colNames{end+1} = varNames{3};
            end
            
            % Column J (rider_name)
            if length(varNames) >= 10
                orderedCols{end+1} = varNames{10}; % rider_name
                colNames{end+1} = varNames{10};
            end
            
            % Column L (team)
            if length(varNames) >= 12
                orderedCols{end+1} = varNames{12}; % team
                colNames{end+1} = varNames{12};
            end
            
            % Column B (bike)
            if length(varNames) >= 2
                orderedCols{end+1} = varNames{2}; % bike
                colNames{end+1} = varNames{2};
            end
            
            % Column A (best_lap_time)
            if length(varNames) >= 1
                orderedCols{end+1} = varNames{1}; % best_lap_time
                colNames{end+1} = varNames{1};
            end
            
            % Column F (lap_number)
            if length(varNames) >= 6
                orderedCols{end+1} = varNames{6}; % lap_number
                colNames{end+1} = varNames{6};
            end
            
            % Column N (total_laps)
            if length(varNames) >= 14
                orderedCols{end+1} = varNames{14}; % total_laps
                colNames{end+1} = varNames{14};
            end
            
            % Column D (gap_to_first)
            if length(varNames) >= 4
                orderedCols{end+1} = varNames{4}; % gap_to_first
                colNames{end+1} = varNames{4};
            end
            
            % Column E (gap_to_previous)
            if length(varNames) >= 5
                orderedCols{end+1} = varNames{5}; % gap_to_previous
                colNames{end+1} = varNames{5};
            end
            
            % Create table with ordered columns
            if ~isempty(orderedCols)
                T_ordered = obj.Data(:, orderedCols);
                
                % Ensure table has exactly 28 rows
                numRows = height(T_ordered);
                if numRows < 28
                    % Pad with empty rows
                    emptyRow = T_ordered(1, :);
                    varNames = emptyRow.Properties.VariableNames;
                    for i = 1:length(varNames)
                        colName = varNames{i};
                        colData = emptyRow.(colName);
                        if isnumeric(colData) || islogical(colData)
                            emptyRow.(colName) = NaN;
                        else
                            emptyRow.(colName) = "";
                        end
                    end
                    needed = 28 - numRows;
                    emptyRows = repmat(emptyRow, needed, 1);
                    T_ordered = [T_ordered; emptyRows];
                elseif numRows > 28
                    % Truncate to 28 rows
                    T_ordered = T_ordered(1:28, :);
                end
                
                % Always replace the first cell under gap_to_first with 0
                gapFirstColName = '';
                for i = 1:length(colNames)
                    if contains(lower(colNames{i}), 'gap_to_first')
                        gapFirstColName = orderedCols{i};
                        break;
                    end
                end
                if ~isempty(gapFirstColName) && height(T_ordered) > 0
                    T_ordered.(gapFirstColName)(1) = 0;
                end
                
                % Replace NaN values with 0 for display
                T_display = T_ordered;
                varNames = T_display.Properties.VariableNames;
                for i = 1:length(varNames)
                    colName = varNames{i};
                    colData = T_display.(colName);
                    if isnumeric(colData)
                        % Replace NaN with 0
                        nanMask = isnan(colData);
                        if any(nanMask)
                            colData(nanMask) = 0;
                            T_display.(colName) = colData;
                        end
                    end
                end
                
                obj.TableData = T_ordered; % Keep original with NaN for calculations
                obj.RidersTable.Data = T_display; % Display version with empty strings
                obj.RidersTable.ColumnName = colNames;
                
                % Table now fits the grid layout automatically, no need to set position
                % The table will size itself based on available space in the grid
                
                % Apply alternating row colors: white for odd rows, light grey for even rows
                obj.applyAlternatingRowColors();
            else
                obj.TableData = table();
                obj.RidersTable.Data = {};
                obj.RidersTable.ColumnName = {};
            end
        end
        
        function updateComboBoxes(obj)
            %UPDATECOMBOBOXES Populate combo boxes with rider names and set defaults
            if isempty(obj.TableData)
                return;
            end
            
            % Get rider names from the table (rider_name column)
            varNames = obj.TableData.Properties.VariableNames;
            riderNameCol = '';
            for i = 1:length(varNames)
                if contains(lower(varNames{i}), 'rider_name') || contains(lower(varNames{i}), 'name')
                    riderNameCol = varNames{i};
                    break;
                end
            end
            
            if isempty(riderNameCol)
                return;
            end
            
            % Get unique rider names
            riderNames = obj.TableData.(riderNameCol);
            if iscell(riderNames)
                riderNames = string(riderNames);
            else
                riderNames = string(riderNames);
            end
            riderNames = unique(riderNames(~ismissing(riderNames)), 'stable');
            riderNames = cellstr(riderNames);
            
            % Update combo boxes
            obj.Rider1DropDown.Items = riderNames;
            obj.Rider2DropDown.Items = riderNames;
            
            % Update laps table combo boxes
            if ~isempty(obj.LapsTable1DropDown)
                obj.LapsTable1DropDown.Items = [{''}; riderNames];
                % Pre-select first rider for LapsTable1DropDown
                if length(riderNames) >= 1
                    obj.LapsTable1DropDown.Value = riderNames{1};
                    % Trigger the change handler to update table
                    obj.onLapsTable1Changed();
                else
                    obj.LapsTable1DropDown.Value = '';
                end
            end
            if ~isempty(obj.LapsTable2DropDown)
                obj.LapsTable2DropDown.Items = [{''}; riderNames];
                % Pre-select second rider for LapsTable2DropDown
                if length(riderNames) >= 2
                    obj.LapsTable2DropDown.Value = riderNames{2};
                    % Trigger the change handler to update table
                    obj.onLapsTable2Changed();
                else
                    obj.LapsTable2DropDown.Value = '';
                end
            end
            
            % Update sectors tab combo boxes
            if ~isempty(obj.Sector1DropDown)
                obj.Sector1DropDown.Items = [{''}; riderNames];
                % Pre-select first rider for Sector1DropDown
                if length(riderNames) >= 1
                    obj.Sector1DropDown.Value = riderNames{1};
                    obj.onSector1Changed();
                else
                    obj.Sector1DropDown.Value = '';
                end
            end
            if ~isempty(obj.Sector2DropDown)
                obj.Sector2DropDown.Items = [{''}; riderNames];
                % Pre-select second rider for Sector2DropDown
                if length(riderNames) >= 2
                    obj.Sector2DropDown.Value = riderNames{2};
                    obj.onSector2Changed();
                else
                    obj.Sector2DropDown.Value = '';
                end
            end
            
            % Ensure column widths are set after UI fully renders (use timer for delay)
            % updateLapsTable already calls fitColumnsToTableWidth, but panel size might not be ready yet
            % Use multiple timer attempts to ensure it works
            if length(riderNames) >= 1
                % First attempt after 0.1 seconds
                t1 = timer('StartDelay', 0.1, 'ExecutionMode', 'singleShot', ...
                    'TimerFcn', @(~,~) obj.ensureLapsTableColumnWidths());
                start(t1);
                % Second attempt after 0.3 seconds
                t2 = timer('StartDelay', 0.3, 'ExecutionMode', 'singleShot', ...
                    'TimerFcn', @(~,~) obj.ensureLapsTableColumnWidths());
                start(t2);
                % Third attempt after 0.8 seconds as backup
                t3 = timer('StartDelay', 0.8, 'ExecutionMode', 'singleShot', ...
                    'TimerFcn', @(~,~) obj.ensureLapsTableColumnWidths());
                start(t3);
            end
            
            % Pre-select first rider for Rider1DropDown and second rider for Rider2DropDown
            if length(riderNames) >= 1
                obj.Rider1DropDown.Value = riderNames{1};
                % Trigger the change handler to update table highlighting
                obj.onRider1Changed();
            else
            obj.Rider1DropDown.Value = '';
            end
            
            if length(riderNames) >= 2
                obj.Rider2DropDown.Value = riderNames{2};
                % Trigger the change handler to update table highlighting
                obj.onRider2Changed();
            else
            obj.Rider2DropDown.Value = '';
            end
        end
        
        function onRider1Changed(obj)
            %ONRIDER1CHANGED Handle rider 1 selection change
            obj.updateRowHighlighting();
        end
        
        function onRider2Changed(obj)
            %ONRIDER2CHANGED Handle rider 2 selection change
            obj.updateRowHighlighting();
        end
        
        function applyAlternatingRowColors(obj)
            %APPLYALTERNATINGROWCOLORS Apply alternating white/grey row colors
            if isempty(obj.TableData)
                return;
            end
            
            numRows = height(obj.TableData);
            numCols = width(obj.TableData);
            
            % Apply alternating row colors: white for odd rows, light grey for even rows
            whiteStyle = uistyle('BackgroundColor', [1 1 1], 'HorizontalAlignment', 'center');
            greyStyle = uistyle('BackgroundColor', [0.94 0.94 0.94], 'HorizontalAlignment', 'center');
            
            % Apply styles row by row
            for r = 1:numRows
                % Create cell indices for this row
                rowCells = [repmat(r, numCols, 1), (1:numCols)'];
                
                % Alternate: row 1 = white, row 2 = grey, row 3 = white, etc.
                if mod(r, 2) == 1
                    % Odd rows: white
                    addStyle(obj.RidersTable, whiteStyle, 'cell', rowCells);
                else
                    % Even rows: light grey
                    addStyle(obj.RidersTable, greyStyle, 'cell', rowCells);
                end
            end
        end
        
        function onTabSelectionChanged(obj, src, event)
            %ONTABSELECTIONCHANGED Callback when nested tab selection changes
            % No longer needed - table is directly in grid layout (no scrollable panel)
            % Kept for potential future use
        end
        
        function onClearButtonPushed(obj)
            %ONCLEARBUTTONPUSHED Clear all highlights, restore original row colors, and reset combo boxes
            if isempty(obj.TableData)
                return;
            end
            
            % Reset combo boxes to empty (no rider selected)
            obj.Rider1DropDown.Value = '';
            obj.Rider2DropDown.Value = '';
            
            % Delete all style objects first
            styleObjs = findall(obj.RidersTable, 'Type', 'uistyle');
            delete(styleObjs);
            
            % Re-apply alternating row colors (same as initial setup)
            obj.applyAlternatingRowColors();
        end
        
        function updateRowHighlighting(obj)
            %UPDATEROWHIGHLIGHTING Update row highlighting based on selected riders
            % Only highlights the currently selected rider for each combo box
            if isempty(obj.TableData)
                return;
            end
            
            % Remove ALL existing styles (including previous highlights)
            styleObjs = findall(obj.RidersTable, 'Type', 'uistyle');
            for i = 1:length(styleObjs)
                removeStyle(obj.RidersTable, styleObjs(i));
            end
            
            % Re-add center alignment
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.RidersTable, centerStyle);
            
            % Get rider name column
            varNames = obj.TableData.Properties.VariableNames;
            riderNameCol = '';
            for i = 1:length(varNames)
                if contains(lower(varNames{i}), 'rider_name') || contains(lower(varNames{i}), 'name')
                    riderNameCol = varNames{i};
                    break;
                end
            end
            
            if isempty(riderNameCol)
                return;
            end
            
            % Get selected riders
            rider1 = obj.Rider1DropDown.Value;
            rider2 = obj.Rider2DropDown.Value;
            
            % Get rider names from table
            riderNames = obj.TableData.(riderNameCol);
            if iscell(riderNames)
                riderNames = string(riderNames);
            else
                riderNames = string(riderNames);
            end
            
            % Highlight ONLY the currently selected rider 1 in red
            if ~isempty(rider1) && ~isequal(rider1, '')
                mask1 = contains(riderNames, rider1, 'IgnoreCase', true);
                if any(mask1)
                    redStyle = uistyle('BackgroundColor', [1 0 0]); % Strong red (same as other tabs)
                    rows1 = find(mask1);
                    numCols = width(obj.TableData);
                    for r = 1:length(rows1)
                        % Create N-by-2 matrix: [row, col] pairs for each cell in the row
                        cellIndices = [repmat(rows1(r), numCols, 1), (1:numCols)'];
                        addStyle(obj.RidersTable, redStyle, 'cell', cellIndices);
                    end
                end
            end
            
            % Highlight ONLY the currently selected rider 2 in strong light blue
            if ~isempty(rider2) && ~isequal(rider2, '')
                mask2 = contains(riderNames, rider2, 'IgnoreCase', true);
                if any(mask2)
                    blueStyle = uistyle('BackgroundColor', [0.3 0.7 1]); % Strong light blue
                    rows2 = find(mask2);
                    numCols = width(obj.TableData);
                    for r = 1:length(rows2)
                        % Create N-by-2 matrix: [row, col] pairs for each cell in the row
                        cellIndices = [repmat(rows2(r), numCols, 1), (1:numCols)'];
                        addStyle(obj.RidersTable, blueStyle, 'cell', cellIndices);
                    end
                end
            end
        end
        
        function onLapsTable1Changed(obj)
            %ONLAPSTABLE1CHANGED Handle laps table 1 rider selection change
            selectedRider = obj.LapsTable1DropDown.Value;
            obj.updateLapsTable(1, selectedRider);
        end
        
        function onLapsTable2Changed(obj)
            %ONLAPSTABLE2CHANGED Handle laps table 2 rider selection change
            selectedRider = obj.LapsTable2DropDown.Value;
            obj.updateLapsTable(2, selectedRider);
        end
        
        function onSector1Changed(obj)
            %ONSECTOR1CHANGED Handle sector 1 rider selection change
            % Clear all styles and re-apply highlights for both riders
            obj.clearSectorsTableStyles();
            obj.updateSectorsHighlighting();
            obj.updateSectorsSummaryHighlighting();
        end
        
        function onSector2Changed(obj)
            %ONSECTOR2CHANGED Handle sector 2 rider selection change
            % Clear all styles and re-apply highlights for both riders
            obj.clearSectorsTableStyles();
            obj.updateSectorsHighlighting();
            obj.updateSectorsSummaryHighlighting();
        end
        
        function clearSectorsTableStyles(obj)
            %CLEARSECTORSTABLESTYLES Clear all styles from sectors table
            % This ensures a clean slate before applying new highlights
            % Uses StyleConfigurations to get styles and removes them by index
            if isempty(obj.SectorsTable) || ~isvalid(obj.SectorsTable)
                return;
            end
            
            % Get the number of styles using StyleConfigurations
            numStyles = size(obj.SectorsTable.StyleConfigurations, 1);
            
            % Remove each style by index, starting from the last one (reverse order)
            if numStyles > 0
                for i = numStyles:-1:1
                    try
                        removeStyle(obj.SectorsTable, i);
                    catch
                        % Ignore errors and continue
                    end
                end
            end
            
            % Re-apply center alignment
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.SectorsTable, centerStyle);
        end
        
        function onSectorsClearButtonPushed(obj)
            %ONSECTORSCLEARBUTTONPUSHED Clear all highlights and reset combo boxes
            % Reset combo boxes to empty
            obj.Sector1DropDown.Value = '';
            obj.Sector2DropDown.Value = '';
            
            % Clear all styles using the same function
            obj.clearSectorsTableStyles();
            obj.clearSectorsSummaryTableStyles();
        end
        
        function updateSectorsHighlighting(obj)
            %UPDATESECTORSHIGHLIGHTING Update highlighting in sectors table based on selected riders
            % Highlights both the rider name cell and the corresponding laptime cell for each sector
            % Note: Styles should be cleared before calling this function (e.g., via clearSectorsTableStyles)
            if isempty(obj.SectorsTable.Data) || ~istable(obj.SectorsTable.Data)
                return;
            end
            
            % Get selected riders (both combo boxes)
            rider1 = obj.Sector1DropDown.Value;
            rider2 = obj.Sector2DropDown.Value;
            
            % Get table data
            tableData = obj.SectorsTable.Data;
            if isempty(tableData) || ~istable(tableData)
                return;
            end
            
            varNames = tableData.Properties.VariableNames;
            numRows = height(tableData);
            
            % Process each sector pair (Name and Laptime columns)
            % Columns are: sector1Names, sector1Times, sector2Names, sector2Times, etc.
            for sectorNum = 1:4
                nameColName = sprintf('sector%dNames', sectorNum);
                laptimeColName = sprintf('sector%dTimes', sectorNum);
                
                % Find column indices
                nameColIdx = find(strcmp(varNames, nameColName), 1);
                laptimeColIdx = find(strcmp(varNames, laptimeColName), 1);
                
                if isempty(nameColIdx) || isempty(laptimeColIdx)
                    continue; % Skip if columns not found
                end
                
                % Get name column data and convert to string array (similar to Riders tab)
                nameColData = tableData.(nameColName);
                if iscell(nameColData)
                    riderNames = string(nameColData);
                elseif isstring(nameColData)
                    riderNames = nameColData;
                else
                    riderNames = string(nameColData);
                end
                
                % Replace missing/empty strings with empty string for proper comparison
                riderNames(ismissing(riderNames)) = "";
                
                % Highlight rider 1 in red - create new style for each row to ensure proper clearing
                if ~isempty(rider1) && ~isequal(rider1, '')
                    mask1 = contains(riderNames, rider1, 'IgnoreCase', true);
                    % Filter out empty strings
                    mask1 = mask1 & (strlength(riderNames) > 0);
                    if any(mask1)
                        rows1 = find(mask1);
                        for r = 1:length(rows1)
                            rowIdx = rows1(r);
                            % Create a new style object for each row to ensure proper clearing
                            redStyle = uistyle('BackgroundColor', [1 0 0], 'HorizontalAlignment', 'center');
                            % Create cell indices for both name and laptime cells (2x2 matrix: [row, col; row, col])
                            cellIndices = [rowIdx, nameColIdx; rowIdx, laptimeColIdx];
                            addStyle(obj.SectorsTable, redStyle, 'cell', cellIndices);
                        end
                    end
                end
                
                % Highlight rider 2 in blue - create new style for each row to ensure proper clearing
                if ~isempty(rider2) && ~isequal(rider2, '')
                    mask2 = contains(riderNames, rider2, 'IgnoreCase', true);
                    % Filter out empty strings
                    mask2 = mask2 & (strlength(riderNames) > 0);
                    if any(mask2)
                        rows2 = find(mask2);
                        for r = 1:length(rows2)
                            rowIdx = rows2(r);
                            % Create a new style object for each row to ensure proper clearing
                            blueStyle = uistyle('BackgroundColor', [0.3 0.7 1], 'HorizontalAlignment', 'center');
                            % Create cell indices for both name and laptime cells (2x2 matrix: [row, col; row, col])
                            cellIndices = [rowIdx, nameColIdx; rowIdx, laptimeColIdx];
                            addStyle(obj.SectorsTable, blueStyle, 'cell', cellIndices);
                        end
                    end
                end
            end
            
            % Force UI update
            drawnow;
        end
        
        function updateLapsTable(obj, tableNum, riderName)
            %UPDATELAPSTABLE Update laps table with filtered data for selected rider
            if isempty(obj.LapsData) || isempty(riderName) || isequal(riderName, '')
                % Clear table if no rider selected or no data
                if tableNum == 1
                    obj.LapsTable1.Data = {};
                    obj.LapsTable1.ColumnName = {};
                    obj.LapsSummaryTable1.Data = {};
                    obj.LapsSummaryTable1.ColumnName = {};
                else
                    obj.LapsTable2.Data = {};
                    obj.LapsTable2.ColumnName = {};
                    obj.LapsSummaryTable2.Data = {};
                    obj.LapsSummaryTable2.ColumnName = {};
                end
                return;
            end
            
            % Filter laps data by rider name
            if ismember('rider_name', obj.LapsData.Properties.VariableNames)
                mask = strcmp(obj.LapsData.rider_name, riderName);
                filteredData = obj.LapsData(mask, :);
            else
                filteredData = table();
            end
            
            if height(filteredData) == 0
                % No data for this rider
                if tableNum == 1
                    obj.LapsTable1.Data = {};
                    obj.LapsTable1.ColumnName = {};
                    obj.LapsSummaryTable1.Data = {};
                    obj.LapsSummaryTable1.ColumnName = {};
                else
                    obj.LapsTable2.Data = {};
                    obj.LapsTable2.ColumnName = {};
                    obj.LapsSummaryTable2.Data = {};
                    obj.LapsSummaryTable2.ColumnName = {};
                end
                return;
            end
            
            % Get column names from CSV (columns D, E, I, J, K, L, O)
            varNames = filteredData.Properties.VariableNames;
            
            % Column D = lap_number (4th column, index 4)
            % Column E = lap_time (5th column, index 5)
            % Column I = sector_1 (9th column, index 9)
            % Column J = sector_2 (10th column, index 10)
            % Column K = sector_3 (11th column, index 11)
            % Column L = sector_4 (12th column, index 12)
            % Column O = speed (15th column, index 15)
            
            orderedCols = {};
            colNames = {};
            
            if length(varNames) >= 4
                orderedCols{end+1} = varNames{4}; % lap_number
                colNames{end+1} = varNames{4};
            end
            if length(varNames) >= 5
                orderedCols{end+1} = varNames{5}; % lap_time
                colNames{end+1} = varNames{5};
            end
            if length(varNames) >= 9
                orderedCols{end+1} = varNames{9}; % sector_1
                colNames{end+1} = varNames{9};
            end
            if length(varNames) >= 10
                orderedCols{end+1} = varNames{10}; % sector_2
                colNames{end+1} = varNames{10};
            end
            if length(varNames) >= 11
                orderedCols{end+1} = varNames{11}; % sector_3
                colNames{end+1} = varNames{11};
            end
            if length(varNames) >= 12
                orderedCols{end+1} = varNames{12}; % sector_4
                colNames{end+1} = varNames{12};
            end
            if length(varNames) >= 15
                orderedCols{end+1} = varNames{15}; % speed
                colNames{end+1} = varNames{15};
            end
            
            if ~isempty(orderedCols)
                T_display = filteredData(:, orderedCols);
                
                % Replace NaN values with 0 for numeric columns
                for i = 1:length(orderedCols)
                    colName = orderedCols{i};
                    if ismember(colName, T_display.Properties.VariableNames)
                        colData = T_display.(colName);
                        if isnumeric(colData)
                            nanMask = isnan(colData);
                            if any(nanMask)
                                colData(nanMask) = 0;
                                T_display.(colName) = colData;
                            end
                        end
                    end
                end
                
                % Update table
                if tableNum == 1
                    % First, clear all existing styles
                    obj.clearAllTableStyles(obj.LapsTable1);
                    
                    % Set the new data
                    % Clear ColumnFormat to avoid warnings when using table Data
                    if isprop(obj.LapsTable1, 'ColumnFormat')
                        obj.LapsTable1.ColumnFormat = {};
                    end
                    obj.LapsTable1.Data = T_display;
                    obj.LapsTable1.ColumnName = colNames;
                    
                    % Reset all cells to default white background with center alignment
                    obj.resetTableBackgrounds(obj.LapsTable1, T_display);
                    
                    % Highlight rows with speed = 0 in dark grey
                    obj.highlightZeroSpeedRows(obj.LapsTable1, T_display);
                    
                    % Apply heatmap to sector columns (pastel colors)
                    obj.applySectorHeatmap(obj.LapsTable1, T_display);
                    
                    % Highlight fastest lap (excluding rows with speed = 0) in red (do this BEFORE sectors)
                    obj.highlightFastestLap(obj.LapsTable1, T_display, [1 0 0]); % Red
                    
                    % Highlight fastest sector times in red (this will show on top of heatmap)
                    obj.highlightFastestSectors(obj.LapsTable1, T_display, [1 0 0]); % Red
                    
                    % Set column widths to fill the table width (after all updates)
                    drawnow;
                    obj.fitColumnsToTableWidth(obj.LapsTable1);
                    
                    % Update summary table with ideal lap time, fastest sectors, and fastest speed
                    obj.updateLapsSummaryTable(1, T_display);
                else
                    % First, clear all existing styles
                    obj.clearAllTableStyles(obj.LapsTable2);
                    
                    % Set the new data
                    obj.LapsTable2.Data = T_display;
                    obj.LapsTable2.ColumnName = colNames;
                    % Clear ColumnFormat AFTER Data assignment to avoid warnings with table Data
                    if isprop(obj.LapsTable2, 'ColumnFormat')
                        obj.LapsTable2.ColumnFormat = {};
                    end
                    
                    % Reset all cells to default white background with center alignment
                    obj.resetTableBackgrounds(obj.LapsTable2, T_display);
                    
                    % Highlight rows with speed = 0 in dark grey
                    obj.highlightZeroSpeedRows(obj.LapsTable2, T_display);
                    
                    % Apply heatmap to sector columns (pastel colors)
                    obj.applySectorHeatmap(obj.LapsTable2, T_display);
                    
                    % Highlight fastest lap (excluding rows with speed = 0) in strong light blue (do this BEFORE sectors)
                    obj.highlightFastestLap(obj.LapsTable2, T_display, [0.3 0.7 1]); % Strong light blue
                    
                    % Highlight fastest sector times in strong light blue (this will show on top of heatmap)
                    obj.highlightFastestSectors(obj.LapsTable2, T_display, [0.3 0.7 1]); % Strong light blue
                    
                    % Set column widths to fill the table width (after all updates)
                    drawnow;
                    obj.fitColumnsToTableWidth(obj.LapsTable2);
                    
                    % Update summary table with ideal lap time, fastest sectors, and fastest speed
                    obj.updateLapsSummaryTable(2, T_display);
                end
            end
        end
        
        function fitColumnsToTableWidth(obj, tableObj)
            %FITCOLUMNSTOTABLEWIDTH Calculate column widths to fill the table width
            % Get the table's parent panel to determine available width
            try
                availableWidth = 0;
                
                % Check if this is the sectors table or speeds table (both are in 2-column grids)
                isSectorsTable = (tableObj == obj.SectorsTable);
                isSpeedsTable = (tableObj == obj.SpeedsTable);
                
                if isvalid(obj.ParentFigure)
                    figureWidth = obj.ParentFigure.Position(3);
                    if figureWidth > 100
                        if isSectorsTable
                            % Sectors table is in a 2-column grid: 2x (sectors) and 1x (summary)
                            % sectorsGrid has padding of 10 on each side = 20 total
                            % Sectors table gets 2/3 of the available width (2x out of 2x+1x=3x total)
                            availableWidth = (figureWidth - 20) * 2/3 - 40; % Grid padding + margin
                        elseif isSpeedsTable
                            % Speeds table is in a 2-column grid: 2x (table) and 1x (graph)
                            % speedsGrid has padding of 10 on each side = 20 total
                            % Speeds table gets 2/3 of the available width (2x out of 2x+1x=3x total)
                            availableWidth = (figureWidth - 20) * 2/3 - 40; % Grid padding + margin
                        else
                            % Laps tables: Two-column layout: each column gets ~50% of width minus padding
                            % lapsGrid has padding of 10 on each side = 20 total
                            % sectionGrid has padding of 5 on each side = 10 total per section
                            availableWidth = (figureWidth - 20) / 2 - 20; % Grid + section padding
                        end
                    end
                end
                
                % Try Position-based width as a refinement, but only if it's larger than figure calculation
                % This ensures we use the most accurate available width, while prioritizing figure calculation
                % on initial load when Position might not be accurate yet
                if isvalid(tableObj) && isprop(tableObj, 'Position') && length(tableObj.Position) >= 3
                    tableWidth = tableObj.Position(3);
                    if tableWidth > 50
                        positionBasedWidth = tableWidth - 20; % Use actual table width minus small margin
                        % Use Position-based width if it's larger (more accurate after layout settles)
                        if positionBasedWidth > availableWidth
                            availableWidth = positionBasedWidth;
                        end
                    end
                end
                
                % Fallback: try parent panel/grid if we still don't have a good width
                if availableWidth <= 50
                    parentPanel = tableObj.Parent;
                    if isvalid(parentPanel) && isprop(parentPanel, 'Position') && length(parentPanel.Position) >= 3
                        if isSectorsTable || isSpeedsTable
                            % For sectors/speeds table, parent is the grid layout
                            gridWidth = parentPanel.Position(3);
                            if gridWidth > 50
                                % Both tables are in column 1 of 2-column grid (2x ratio)
                                availableWidth = gridWidth * 2/3 - 40;
                            end
                        else
                            panelWidth = parentPanel.Position(3);
                            if panelWidth > 50
                                availableWidth = panelWidth - 30;
                            end
                        end
                    end
                end
                
                % Get number of columns from the table data
                numCols = 0;
                if istable(tableObj.Data) && width(tableObj.Data) > 0
                    numCols = width(tableObj.Data);
                elseif ~isempty(tableObj.ColumnName) && length(tableObj.ColumnName) > 0
                    numCols = length(tableObj.ColumnName);
                end
                
                if numCols > 0 && availableWidth > 50
                    % Check if this is the speeds table - need to exclude hidden columns (Max-Avg and Range)
                    isSpeedsTableForWidth = (tableObj == obj.SpeedsTable);
                    hiddenColIndices = [];
                    
                    if isSpeedsTableForWidth && ~isempty(tableObj.ColumnName)
                        maxAvgIdx = find(strcmp(tableObj.ColumnName, 'Max-Avg'), 1);
                        rangeIdx = find(strcmp(tableObj.ColumnName, 'Range'), 1);
                        if ~isempty(maxAvgIdx)
                            hiddenColIndices(end+1) = maxAvgIdx;
                        end
                        if ~isempty(rangeIdx)
                            hiddenColIndices(end+1) = rangeIdx;
                        end
                    end
                    
                    visibleCols = numCols - length(hiddenColIndices);
                    
                    % Calculate equal width for each visible column to fill the available width
                    if visibleCols > 0
                        colWidth = floor(availableWidth / visibleCols);
                        columnWidths = cell(1, numCols);
                        
                        % Set widths: 0 for hidden columns, calculated width for visible columns
                        for i = 1:numCols
                            if ismember(i, hiddenColIndices)
                                columnWidths{i} = 0; % Hide this column
                            else
                                columnWidths{i} = colWidth;
                            end
                        end
                        
                        % Distribute remainder to last visible column to ensure full width is used
                        remainder = availableWidth - (colWidth * visibleCols);
                        if remainder > 0
                            % Find last visible column
                            for i = numCols:-1:1
                                if ~ismember(i, hiddenColIndices)
                                    columnWidths{i} = colWidth + remainder;
                                    break;
                                end
                            end
                        end
                        
                        tableObj.ColumnWidth = columnWidths;
                    end
                end
            catch ME
                % If calculation fails, use 'fit' as fallback
                warning('RythmTab:ColumnWidthError', 'Could not calculate column widths: %s', ME.message);
                tableObj.ColumnWidth = 'fit';
            end
        end
        
        function applySectorHeatmap(obj, tableObj, tableData)
            %APPLYSECTORHEATMAP Apply pastel heatmap colors to sector, lap_time, and speed columns
            % Each column gets its own heatmap based on its values
            % Fastest (lowest) times get light pastel green, slowest get light pastel red
            % For speed: highest speeds get green, lowest get red (opposite direction)
            
            try
                % Find columns to apply heatmap: sector columns, lap_time, and speed
                varNames = tableData.Properties.VariableNames;
                heatmapCols = {};
                heatmapIndices = [];
                
                for i = 1:length(varNames)
                    colName = varNames{i};
                    colNameLower = lower(colName);
                    % Include sector columns, lap_time, and speed columns
                    if contains(colNameLower, 'sector') || ...
                       contains(colNameLower, 'lap_time') || ...
                       contains(colNameLower, 'speed')
                        heatmapCols{end+1} = colName;
                        heatmapIndices(end+1) = i;
                    end
                end
                
                if isempty(heatmapCols)
                    return;
                end
                
                % Find speed column for filtering
                speedColIdx = find(contains(lower(varNames), 'speed'), 1);
                speedColName = [];
                if ~isempty(speedColIdx)
                    speedColName = varNames{speedColIdx};
                end
                
                numRows = height(tableData);
                if numRows <= 1
                    return;
                end
                
                % Create mask for valid rows: exclude first row and rows with speed = 0
                validRows = true(numRows, 1);
                validRows(1) = false; % Ignore first row
                
                if ~isempty(speedColName)
                    speedData = tableData.(speedColName);
                    if isnumeric(speedData)
                        validRows = validRows & (speedData ~= 0);
                    end
                end
                
                % Process each heatmap column separately
                for i = 1:length(heatmapCols)
                    colName = heatmapCols{i};
                    colIndex = heatmapIndices(i);
                    colNameLower = lower(colName);
                    
                    % Get column data
                    colData = tableData.(colName);
                    
                    % Convert lap_time from string format "M'SS.mmm" to numeric seconds if needed
                    if isnumeric(colData)
                        numericData = colData;
                    elseif contains(colNameLower, 'lap_time')
                        % Parse lap_time format "M'SS.mmm" to numeric seconds
                        numericData = zeros(numRows, 1);
                        if isstring(colData) || iscell(colData) || ischar(colData)
                            for r = 1:numRows
                                if iscell(colData)
                                    lapTimeStr = char(colData{r});
                                elseif isstring(colData)
                                    lapTimeStr = char(colData(r));
                                else
                                    lapTimeStr = colData;
                                end
                                
                                % Parse format "M'SS.mmm"
                                tokens = regexp(lapTimeStr, '''', 'split');
                                if length(tokens) == 2
                                    minutes = str2double(tokens{1});
                                    seconds = str2double(tokens{2});
                                    if ~isnan(minutes) && ~isnan(seconds)
                                        numericData(r) = minutes * 60 + seconds;
                                    else
                                        numericData(r) = NaN;
                                    end
                                else
                                    % Try to parse as plain number
                                    numericData(r) = str2double(lapTimeStr);
                                end
                            end
                        else
                            numericData(:) = NaN;
                        end
                    else
                        % Not numeric and not lap_time, skip
                        continue;
                    end
                    
                    if isnumeric(numericData)
                        % Create valid data mask (exclude zeros, NaN, and invalid rows)
                        validData = numericData;
                        validData(validData == 0) = NaN;
                        validData(~validRows) = NaN;
                        
                        % Find min and max for this column (excluding invalid values)
                        validNonNan = validData(~isnan(validData));
                        if isempty(validNonNan)
                            continue;
                        end
                        
                        minVal = min(validNonNan);
                        maxVal = max(validNonNan);
                        
                        % Only apply heatmap if we have valid data with range
                        if ~isempty(minVal) && ~isempty(maxVal) && ~isnan(minVal) && ~isnan(maxVal) && minVal < maxVal
                            % 2-color gradient: Light Green -> Dark Green
                            % Make 25% transparent by blending with white (25% = 0.25 * color + 0.75 * white)
                            baseLightGreen = [0.6 1.0 0.6];   % Light green
                            baseDarkGreen = [0.0 0.5 0.0];    % Dark green
                            white = [1.0 1.0 1.0];            % White for blending
                            
                            % Apply 25% transparency (25% = 0.25 * color + 0.75 * white)
                            lightGreenColor = 0.25 * baseLightGreen + 0.75 * white;
                            darkGreenColor = 0.25 * baseDarkGreen + 0.75 * white;
                            
                            % For speed columns, reverse the direction (higher is better)
                            % For lap_time and sectors, lower is better (normal direction)
                            isSpeedColumn = contains(colNameLower, 'speed');
                            
                            % Apply colors to each cell in this column
                            for r = 1:numRows
                                if validRows(r) && ~isnan(numericData(r)) && numericData(r) > 0
                                    % Calculate normalized value [0, 1]
                                    normalizedVal = (numericData(r) - minVal) / (maxVal - minVal);
                                    normalizedVal = max(0, min(1, normalizedVal)); % Clamp to [0, 1]
                                    
                                    % For speed columns, reverse the direction
                                    if isSpeedColumn
                                        normalizedVal = 1 - normalizedVal;
                                    end
                                    
                                    % Interpolate between light green and dark green
                                    % Light green for best values (0), dark green for worst values (1)
                                    cellColor = lightGreenColor * (1 - normalizedVal) + darkGreenColor * normalizedVal;
                                    
                                    % Create style for this cell
                                    heatmapStyle = uistyle('BackgroundColor', cellColor, 'HorizontalAlignment', 'center');
                                    addStyle(tableObj, heatmapStyle, 'cell', [r, colIndex]);
                                end
                            end
                        end
                    end
                end
            catch ME
                warning('RythmTab:HeatmapError', 'Error applying sector heatmap: %s', ME.message);
            end
        end
        
        function highlightFastestSectors(obj, tableObj, tableData, highlightColor)
            %HIGHLIGHTFASTESTSECTORS Highlight the fastest (lowest) value in each sector column
            % Ignores first row when finding fastest sectors
            % Excludes rows where speed = 0 (same as highlightFastestLap)
            
            % Find sector column indices (sector_1, sector_2, sector_3, sector_4)
            varNames = tableData.Properties.VariableNames;
            sectorCols = {};
            sectorIndices = [];
            
            for i = 1:length(varNames)
                colName = varNames{i};
                if contains(lower(colName), 'sector')
                    sectorCols{end+1} = colName;
                    sectorIndices(end+1) = i;
                end
            end
            
            if isempty(sectorCols)
                return;
            end
            
            % Find speed column for filtering out zero-speed rows
            speedColIdx = find(contains(lower(varNames), 'speed'), 1);
            speedColName = [];
            if ~isempty(speedColIdx)
                speedColName = varNames{speedColIdx};
            end
            
            % For each sector column, find the row with the minimum value
            numRows = height(tableData);
            
            % Only process if we have more than 1 row (need rows beyond first to highlight)
            if numRows <= 1
                return;
            end
            
            % Create mask for valid rows: exclude first row and rows with speed = 0
            validRows = true(numRows, 1);
            validRows(1) = false; % Ignore first row
            
            % Exclude rows with speed = 0 if speed column exists
            if ~isempty(speedColName)
                speedData = tableData.(speedColName);
                if isnumeric(speedData)
                    validRows = validRows & (speedData ~= 0);
                end
            end
            
            for i = 1:length(sectorCols)
                colName = sectorCols{i};
                colIndex = sectorIndices(i);
                
                % Get column data
                colData = tableData.(colName);
                
                % Convert to numeric if needed and filter out zeros and invalid rows
                if isnumeric(colData)
                    % Create a copy for finding minimum
                    validData = colData;
                    validData(validData == 0) = NaN; % Treat zeros as invalid
                    validData(~validRows) = NaN; % Exclude invalid rows (first row and zero-speed rows)
                    
                    % Find minimum value (excluding first row, zeros/NaN, and zero-speed rows)
                    [minVal, minRow] = min(validData);
                    
                    % Only highlight if we found a valid minimum and it's not the first row
                    if ~isnan(minVal) && minRow > 1 && minRow <= numRows
                        % Create highlight style
                        % Note: uistyle doesn't support BorderColor/BorderWidth, so we use a darker shade
                        % to make the highlight stand out from the heatmap
                        highlightStyle = uistyle('BackgroundColor', highlightColor, 'HorizontalAlignment', 'center');
                        % Apply to the cell at [minRow, colIndex]
                        addStyle(tableObj, highlightStyle, 'cell', [minRow, colIndex]);
                    end
                end
            end
        end
        
        function highlightFastestLap(obj, tableObj, tableData, highlightColor)
            %HIGHLIGHTFASTESTLAP Highlight the fastest lap (lowest lap_time) in the entire row
            % Excludes rows where speed = 0
            % Ignores first row when finding fastest lap
            
            try
                % Find lap_time column (try both 'lap_time' and variations)
                varNames = tableData.Properties.VariableNames;
                lapTimeColIdx = [];
                
                % Try exact match first
                lapTimeColIdx = find(strcmpi(varNames, 'lap_time'), 1);
                if isempty(lapTimeColIdx)
                    % Try contains match
                    lapTimeColIdx = find(contains(lower(varNames), 'lap_time'), 1);
                end
                
                if isempty(lapTimeColIdx)
                    return; % No lap_time column found
                end
                
                lapTimeColName = varNames{lapTimeColIdx};
                lapTimeData = tableData.(lapTimeColName);
                
                
                % Find the column index in the displayed table (columns might be reordered)
                % Get the actual column names from tableData
                displayedVarNames = tableData.Properties.VariableNames;
                lapTimeDisplayColIdx = find(strcmpi(displayedVarNames, lapTimeColName), 1);
                if isempty(lapTimeDisplayColIdx)
                    lapTimeDisplayColIdx = lapTimeColIdx; % Fallback to original index
                end
                
                % Find speed column
                speedColIdx = find(contains(lower(varNames), 'speed'), 1);
                speedColName = [];
                if ~isempty(speedColIdx)
                    speedColName = varNames{speedColIdx};
                end
                
                numRows = height(tableData);
                
                % Only process if we have more than 1 row
                if numRows <= 1
                    return;
                end
                
                % Convert lap times to numeric (seconds) if they're strings in format "M'SS.mmm"
                lapTimesNumeric = zeros(numRows, 1);
                if isnumeric(lapTimeData)
                    lapTimesNumeric = double(lapTimeData);
                elseif isstring(lapTimeData) || iscell(lapTimeData) || ischar(lapTimeData)
                    % Parse format "M'SS.mmm" (minutes'seconds.milliseconds)
                    for r = 1:numRows
                        if iscell(lapTimeData)
                            lapTimeStr = char(lapTimeData{r});
                        elseif isstring(lapTimeData)
                            lapTimeStr = char(lapTimeData(r));
                        else
                            lapTimeStr = lapTimeData;
                        end
                        
                        % Parse format "M'SS.mmm"
                        tokens = regexp(lapTimeStr, '''', 'split');
                        if length(tokens) == 2
                            minutes = str2double(tokens{1});
                            seconds = str2double(tokens{2});
                            if ~isnan(minutes) && ~isnan(seconds)
                                lapTimesNumeric(r) = minutes * 60 + seconds;
                            else
                                lapTimesNumeric(r) = NaN;
                            end
                        else
                            % Try to parse as plain number
                            lapTimesNumeric(r) = str2double(lapTimeStr);
                        end
                    end
                else
                    lapTimesNumeric(:) = NaN;
                end
                
                % Create mask for valid rows: exclude first row and rows with speed = 0
                validRows = true(numRows, 1);
                validRows(1) = false; % Ignore first row
                
                % Exclude rows with speed = 0 if speed column exists
                if ~isempty(speedColName)
                    speedData = tableData.(speedColName);
                    if isnumeric(speedData)
                        validRows = validRows & (speedData ~= 0);
                    end
                end
                
                % Get valid lap times (treat zeros and NaN as invalid)
                validLapTimes = lapTimesNumeric;
                validLapTimes(validLapTimes == 0) = NaN;
                validLapTimes(~validRows) = NaN; % Exclude invalid rows
                
                % Find minimum lap time
                [minLapTime, minRow] = min(validLapTimes);
                
                % Only highlight if we found a valid minimum and it's not the first row
                if ~isnan(minLapTime) && minRow > 1 && minRow <= numRows
                    % Create highlight style (same approach as highlightFastestSectors)
                    highlightStyle = uistyle('BackgroundColor', highlightColor, 'HorizontalAlignment', 'center');
                    
                    % Highlight only the lap_time cell (not the entire row)
                    addStyle(tableObj, highlightStyle, 'cell', [minRow, lapTimeDisplayColIdx]);
                end
            catch ME
                warning('RythmTab:HighlightFastestLapError', 'Error highlighting fastest lap: %s', ME.message);
            end
        end
        
        function updateLapsSummaryTable(obj, tableNum, tableData)
            %UPDATELAPSSUMMARYTABLE Update summary table with ideal lap time, fastest sectors, and fastest speed
            % tableNum: 1 for left table, 2 for right table
            % tableData: The filtered laps data table
            
            try
                % Find sector column names (sector_1, sector_2, sector_3, sector_4)
                varNames = tableData.Properties.VariableNames;
                sectorCols = {};
                sectorIndices = [];
                
                for i = 1:length(varNames)
                    colName = varNames{i};
                    if contains(lower(colName), 'sector')
                        sectorCols{end+1} = colName;
                        sectorIndices(end+1) = i;
                    end
                end
                
                % Sort sectors by number if possible (sector_1, sector_2, etc.)
                if ~isempty(sectorCols)
                    % Extract sector numbers and sort
                    sectorNums = zeros(size(sectorCols));
                    for i = 1:length(sectorCols)
                        colName = sectorCols{i};
                        % Try to extract number from column name (e.g., "sector_1" -> 1)
                        tokens = regexp(colName, '(\d+)', 'tokens');
                        if ~isempty(tokens) && ~isempty(tokens{1})
                            sectorNums(i) = str2double(tokens{1}{1});
                        else
                            sectorNums(i) = i; % Fallback to order
                        end
                    end
                    [~, sortIdx] = sort(sectorNums);
                    sectorCols = sectorCols(sortIdx);
                    sectorIndices = sectorIndices(sortIdx);
                end
                
                % Find fastest (minimum) time for each sector (excluding first row)
                fastestSectors = zeros(1, length(sectorCols));
                numRows = height(tableData);
                
                for i = 1:length(sectorCols)
                    colName = sectorCols{i};
                    colData = tableData.(colName);
                    
                    if isnumeric(colData) && numRows > 1
                        % Create copy for finding minimum, excluding first row
                        validData = colData;
                        validData(validData == 0) = NaN; % Treat zeros as invalid
                        validDataForMin = validData;
                        validDataForMin(1) = NaN; % Ignore first row
                        
                        minVal = min(validDataForMin);
                        if ~isnan(minVal)
                            fastestSectors(i) = minVal;
                        else
                            fastestSectors(i) = 0;
                        end
                    else
                        fastestSectors(i) = 0;
                    end
                end
                
                % Calculate ideal lap time (sum of fastest sectors)
                idealLapTimeSeconds = sum(fastestSectors);
                
                % Format ideal lap time as "M'SS.mmm" (minutes'seconds.milliseconds)
                if idealLapTimeSeconds > 0
                    minutes = floor(idealLapTimeSeconds / 60);
                    remainingSeconds = idealLapTimeSeconds - (minutes * 60);
                    idealLapTimeFormatted = sprintf('%d''%.3f', minutes, remainingSeconds);
                else
                    idealLapTimeFormatted = '0''0.000';
                end
                
                % Find fastest speed (maximum speed value)
                fastestSpeed = 0;
                speedColIdx = find(contains(lower(varNames), 'speed'), 1);
                if ~isempty(speedColIdx) && numRows > 0
                    speedColName = varNames{speedColIdx};
                    speedData = tableData.(speedColName);
                    if isnumeric(speedData)
                        % Exclude zeros (which might be NaN replacements)
                        validSpeed = speedData;
                        validSpeed(validSpeed == 0) = NaN;
                        maxSpeed = max(validSpeed);
                        if ~isnan(maxSpeed)
                            fastestSpeed = maxSpeed;
                        end
                    end
                end
                
                % Create column names: Ideal_Laptime, sector_1, sector_2, sector_3, sector_4, max_speed
                colNames = {'Ideal_Laptime'};
                for i = 1:length(sectorCols)
                    % Use the sector column name directly (e.g., "sector_1")
                    colNames{end+1} = sectorCols{i};
                end
                colNames{end+1} = 'max_speed';
                
                % Create summary data row (Ideal Lap Time as string, sectors and speed as numbers)
                summaryDataCell = cell(1, length(colNames));
                summaryDataCell{1} = idealLapTimeFormatted;
                for i = 1:length(fastestSectors)
                    summaryDataCell{i+1} = fastestSectors(i);
                end
                summaryDataCell{end} = fastestSpeed;
                
                % Create table with single row
                summaryTable = cell2table(summaryDataCell, 'VariableNames', colNames);
                
                % Update the appropriate summary table
                if tableNum == 1
                    summaryTableObj = obj.LapsSummaryTable1;
                else
                    summaryTableObj = obj.LapsSummaryTable2;
                end
                
                % Clear ColumnFormat to avoid warnings (must be before Data assignment)
                if isprop(summaryTableObj, 'ColumnFormat')
                    summaryTableObj.ColumnFormat = {};
                end
                
                % Assign table data - column names should be automatically set from table VariableNames
                summaryTableObj.Data = summaryTable;
                
                % Explicitly set column names to ensure they display (table VariableNames should match)
                summaryTableObj.ColumnName = colNames;
                
                % Clear existing styles first
                styleObjs = findall(summaryTableObj, 'Type', 'uistyle');
                for i = 1:length(styleObjs)
                    try
                        removeStyle(summaryTableObj, styleObjs(i));
                    catch
                        % Ignore errors
                    end
                end
                
                % Set column widths to fit
                obj.fitColumnsToTableWidth(summaryTableObj);
                
                % Apply center alignment and dark green background to all cells except first column
                % Get the darkest green color from heatmap (25% transparency)
                baseDarkGreen = [0.0 0.5 0.0];    % Base dark green
                white = [1.0 1.0 1.0];            % White for blending
                darkGreenColor = 0.25 * baseDarkGreen + 0.75 * white;  % 25% transparency
                
                % Get table dimensions
                numRows = height(summaryTable);
                numCols = width(summaryTable);
                
                if numRows > 0 && numCols > 0
                    % Center alignment for all cells
                    centerStyle = uistyle('HorizontalAlignment', 'center');
                    addStyle(summaryTableObj, centerStyle);
                    
                    % Dark green background for all cells except first column (column 1)
                    if numCols > 1
                        % Create cell indices for all cells except column 1
                        cellIndices = [];
                        for r = 1:numRows
                            for c = 2:numCols  % Start from column 2
                                cellIndices(end+1, :) = [r, c];
                            end
                        end
                        
                        if ~isempty(cellIndices)
                            darkGreenStyle = uistyle('BackgroundColor', darkGreenColor, 'HorizontalAlignment', 'center');
                            addStyle(summaryTableObj, darkGreenStyle, 'cell', cellIndices);
                        end
                    end
                end
                
                % Set column widths to fill the table width
                obj.fitColumnsToTableWidth(summaryTableObj);
                
            catch ME
                warning('RythmTab:UpdateLapsSummaryTableError', ...
                    'Error updating laps summary table: %s', ME.message);
                % Set empty table
                if tableNum == 1
                    obj.LapsSummaryTable1.Data = {};
                    obj.LapsSummaryTable1.ColumnName = {};
                else
                    obj.LapsSummaryTable2.Data = {};
                    obj.LapsSummaryTable2.ColumnName = {};
                end
            end
        end
        
        function updateSectorsTable(obj)
            %UPDATESECTORSTABLE Update sectors table with sorted rider positions per sector
            try
                if isempty(obj.SectorsData) || ~isa(obj.SectorsData, 'table')
                    % Set empty table with column headers
                    obj.SectorsTable.Data = cell(0, 9);
                    obj.SectorsTable.ColumnName = {'Position', 'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                                   'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                                   'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                                   'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
                    return;
                end
                
                % Check if required columns exist
                varNames = obj.SectorsData.Properties.VariableNames;
                if ~ismember('sector_number', varNames) || ...
                   ~ismember('rider_name', varNames) || ...
                   ~ismember('sector_time', varNames)
                    % Set empty table with column headers
                    obj.SectorsTable.Data = cell(0, 9);
                    obj.SectorsTable.ColumnName = {'Position', 'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                                   'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                                   'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                                   'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
                    return;
                end
                
                % Process each sector (1-4)
            allSectorResults = cell(4, 1); % Store results for each sector
            
            for sectorNum = 1:4
                % Filter data for this sector
                % Handle both numeric and string sector_number values
                sectorNumberData = obj.SectorsData.sector_number;
                if isnumeric(sectorNumberData)
                    sectorMask = sectorNumberData == sectorNum;
                elseif iscell(sectorNumberData) || isstring(sectorNumberData) || ischar(sectorNumberData)
                    sectorMask = strcmp(string(sectorNumberData), string(sectorNum));
                else
                    sectorMask = double(sectorNumberData) == sectorNum;
                end
                sectorData = obj.SectorsData(sectorMask, :);
                
                if height(sectorData) == 0
                    % No data for this sector
                    allSectorResults{sectorNum} = table('Size', [0, 2], ...
                        'VariableTypes', {'string', 'double'}, ...
                        'VariableNames', {'RiderName', 'BestTime'});
                    continue;
                end
                
                % Get unique riders - convert to string for consistent handling
                riderNamesRaw = sectorData.rider_name;
                if iscell(riderNamesRaw)
                    riderNamesRaw = string(riderNamesRaw);
                end
                riderNamesRaw = string(riderNamesRaw); % Ensure string array
                uniqueRiders = unique(riderNamesRaw, 'stable');
                
                % For each rider, find their best (minimum) sector time
                riderNames = {};
                bestTimes = [];
                
                for i = 1:length(uniqueRiders)
                    rider = string(uniqueRiders(i));
                    % Compare rider names using string comparison
                    riderMask = strcmp(riderNamesRaw, rider);
                    riderSectorTimes = sectorData.sector_time(riderMask);
                    
                    % Find minimum (best) time, ignoring NaN and invalid values
                    % Convert to numeric if needed
                    if isnumeric(riderSectorTimes)
                        validTimes = riderSectorTimes(~isnan(riderSectorTimes) & riderSectorTimes > 0);
                    else
                        riderSectorTimes = double(riderSectorTimes);
                        validTimes = riderSectorTimes(~isnan(riderSectorTimes) & riderSectorTimes > 0);
                    end
                    if ~isempty(validTimes)
                        bestTime = min(validTimes);
                        riderNames{end+1} = string(rider);
                        bestTimes(end+1) = bestTime;
                    end
                end
                
                % Sort by best time (ascending - fastest first)
                if ~isempty(bestTimes)
                    [sortedTimes, sortIdx] = sort(bestTimes);
                    sortedRiderNames = riderNames(sortIdx);
                    
                    % Create table for this sector
                    sectorTable = table(sortedRiderNames', sortedTimes', ...
                        'VariableNames', {'RiderName', 'BestTime'});
                    allSectorResults{sectorNum} = sectorTable;
                else
                    allSectorResults{sectorNum} = table('Size', [0, 2], ...
                        'VariableTypes', {'string', 'double'}, ...
                        'VariableNames', {'RiderName', 'BestTime'});
                end
            end
            
            % Combine all sectors into one table with 8 columns
            % Find the maximum number of rows across all sectors
            maxRows = 0;
            for i = 1:4
                maxRows = max(maxRows, height(allSectorResults{i}));
            end
            
            if maxRows == 0
                % No data, but show column headers
                obj.SectorsTable.Data = cell(0, 9);
                obj.SectorsTable.ColumnName = {'Position', 'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                               'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                               'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                               'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
                return;
            end
            
            % Create the combined table using a table object (similar to LapsTable)
            % Initialize columns: position first, then sector names and times
            position = (1:maxRows)';  % Position column: 1, 2, 3, ...
            sector1Names = strings(maxRows, 1);
            sector1Times = NaN(maxRows, 1);
            sector2Names = strings(maxRows, 1);
            sector2Times = NaN(maxRows, 1);
            sector3Names = strings(maxRows, 1);
            sector3Times = NaN(maxRows, 1);
            sector4Names = strings(maxRows, 1);
            sector4Times = NaN(maxRows, 1);
            
            for sectorNum = 1:4
                sectorTable = allSectorResults{sectorNum};
                numRowsInSector = height(sectorTable);
                
                % Fill rider names and times directly based on sector number
                % Convert rider names to strings
                if sectorNum == 1
                    % Fill rider names - convert to strings
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            riderNameVal = sectorTable.RiderName(r);
                            sector1Names(r) = string(riderNameVal);
                        end
                    end
                    % Fill remaining rows with empty strings
                    for r = (numRowsInSector + 1):maxRows
                        sector1Names(r) = "";
                    end
                    % Fill lap times
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            sector1Times(r) = double(sectorTable.BestTime(r));
                        end
                    end
                elseif sectorNum == 2
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            riderNameVal = sectorTable.RiderName(r);
                            sector2Names(r) = string(riderNameVal);
                        end
                    end
                    for r = (numRowsInSector + 1):maxRows
                        sector2Names(r) = "";
                    end
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            sector2Times(r) = double(sectorTable.BestTime(r));
                        end
                    end
                elseif sectorNum == 3
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            riderNameVal = sectorTable.RiderName(r);
                            sector3Names(r) = string(riderNameVal);
                        end
                    end
                    for r = (numRowsInSector + 1):maxRows
                        sector3Names(r) = "";
                    end
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            sector3Times(r) = double(sectorTable.BestTime(r));
                        end
                    end
                else % sectorNum == 4
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            riderNameVal = sectorTable.RiderName(r);
                            sector4Names(r) = string(riderNameVal);
                        end
                    end
                    for r = (numRowsInSector + 1):maxRows
                        sector4Names(r) = "";
                    end
                    if numRowsInSector > 0
                        for r = 1:numRowsInSector
                            sector4Times(r) = double(sectorTable.BestTime(r));
                        end
                    end
                end
            end
            
            % Create table object (Position first, then sector columns)
            combinedTable = table(position, sector1Names, sector1Times, ...
                                  sector2Names, sector2Times, ...
                                  sector3Names, sector3Times, ...
                                  sector4Names, sector4Times);
            
            % Update the table
            % Clear ColumnFormat to avoid warnings when using table Data
            if isprop(obj.SectorsTable, 'ColumnFormat')
                obj.SectorsTable.ColumnFormat = {};
            end
            obj.SectorsTable.Data = combinedTable;
            obj.SectorsTable.ColumnName = {'Position', 'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                           'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                           'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                           'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
            
            % Force table refresh first
            drawnow;
            
            % Set column widths to fill the table width (call after drawnow to ensure table is rendered)
            obj.fitColumnsToTableWidth(obj.SectorsTable);
            
            % Also use multiple timers to ensure column widths are set after UI fully renders
            t1 = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.1, ...
                      'TimerFcn', @(~,~) obj.fitColumnsToTableWidth(obj.SectorsTable));
            start(t1);
            t2 = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.3, ...
                      'TimerFcn', @(~,~) obj.fitColumnsToTableWidth(obj.SectorsTable));
            start(t2);
            t3 = timer('ExecutionMode', 'singleShot', 'StartDelay', 0.8, ...
                      'TimerFcn', @(~,~) obj.fitColumnsToTableWidth(obj.SectorsTable));
            start(t3);
            
                % Apply center alignment (if not already applied)
                styleObjs = findall(obj.SectorsTable, 'Type', 'uistyle');
                if isempty(styleObjs)
                    centerStyle = uistyle('HorizontalAlignment', 'center');
                    addStyle(obj.SectorsTable, centerStyle);
                end
                
                % Update highlighting based on selected riders (clear first, then highlight)
                obj.clearSectorsTableStyles();
                obj.updateSectorsHighlighting();
                obj.updateSectorsSummaryTable();
            catch ME
                warning('RythmTab:UpdateSectorsTableError', ...
                    'Error updating sectors table: %s', ME.message);
                % Set empty table with column headers on error
                obj.SectorsTable.Data = cell(0, 9);
                obj.SectorsTable.ColumnName = {'Position', 'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                               'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                               'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                               'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
            end
        end
        
        function updateSectorsSummaryTable(obj)
            %UPDATESECTORSSUMMARYTABLE Update summary table with position, ideal laptime, and best laptime for each rider
            try
                if isempty(obj.SectorsTable.Data) || ~istable(obj.SectorsTable.Data)
                    % Clear summary table
                    if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                        obj.SectorsSummaryTable.ColumnFormat = {};
                    end
                    obj.SectorsSummaryTable.Data = {};
                    return;
                end
                
                sectorsTableData = obj.SectorsTable.Data;
                numRows = height(sectorsTableData);
                
                if numRows == 0
                    % Clear summary table
                    if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                        obj.SectorsSummaryTable.ColumnFormat = {};
                    end
                    obj.SectorsSummaryTable.Data = {};
                    return;
                end
                
                % Get all unique riders from the sectors table
                % Collect riders from all sector columns
                allRiders = {};
                for sectorNum = 1:4
                    nameColName = sprintf('sector%dNames', sectorNum);
                    if ismember(nameColName, sectorsTableData.Properties.VariableNames)
                        nameColData = sectorsTableData.(nameColName);
                        if iscell(nameColData)
                            nameColData = string(nameColData);
                        elseif ~isstring(nameColData)
                            nameColData = string(nameColData);
                        end
                        % Add non-empty riders
                        for r = 1:numRows
                            rider = string(nameColData(r));
                            if ~ismissing(rider) && strlength(rider) > 0
                                allRiders{end+1} = char(rider);
                            end
                        end
                    end
                end
                
                % Get unique riders
                uniqueRiders = unique(allRiders, 'stable');
                
                if isempty(uniqueRiders)
                    % Clear summary table
                    if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                        obj.SectorsSummaryTable.ColumnFormat = {};
                    end
                    obj.SectorsSummaryTable.Data = {};
                    return;
                end
                
                % Initialize arrays for summary data
                riderNames = strings(length(uniqueRiders), 1);
                positions = zeros(length(uniqueRiders), 1);
                idealLaptimes = strings(length(uniqueRiders), 1);
                bestLaptimes = strings(length(uniqueRiders), 1);
                
                % Get TableData for positions
                ridersTableData = obj.TableData;
                
                % Get LapsData for best lap times
                lapsData = obj.LapsData;
                
                % Process each rider
                for i = 1:length(uniqueRiders)
                    riderName = uniqueRiders{i};
                    riderNames(i) = riderName;
                    
                    % Get position from riders table
                    position = NaN;
                    if ~isempty(ridersTableData) && istable(ridersTableData)
                        if ismember('rider_name', ridersTableData.Properties.VariableNames)
                            riderNamesInTable = ridersTableData.rider_name;
                            if iscell(riderNamesInTable)
                                riderNamesInTable = string(riderNamesInTable);
                            end
                            riderMask = strcmpi(string(riderNamesInTable), riderName);
                            if any(riderMask)
                                if ismember('position', ridersTableData.Properties.VariableNames)
                                    positionData = ridersTableData.position(riderMask);
                                    if isnumeric(positionData)
                                        position = positionData(1);
                                    end
                                end
                            end
                        end
                    end
                    positions(i) = position;
                    
                    % Calculate ideal laptime (sum of best sector times for this rider)
                    idealLaptimeSeconds = 0;
                    for sectorNum = 1:4
                        nameColName = sprintf('sector%dNames', sectorNum);
                        timeColName = sprintf('sector%dTimes', sectorNum);
                        if ismember(nameColName, sectorsTableData.Properties.VariableNames) && ...
                           ismember(timeColName, sectorsTableData.Properties.VariableNames)
                            nameColData = sectorsTableData.(nameColName);
                            timeColData = sectorsTableData.(timeColName);
                            if iscell(nameColData)
                                nameColData = string(nameColData);
                            end
                            % Find this rider's best time in this sector
                            riderMask = strcmpi(string(nameColData), riderName);
                            if any(riderMask)
                                riderTimes = timeColData(riderMask);
                                riderTimes = riderTimes(~isnan(riderTimes) & riderTimes > 0);
                                if ~isempty(riderTimes)
                                    idealLaptimeSeconds = idealLaptimeSeconds + min(riderTimes);
                                end
                            end
                        end
                    end
                    
                    % Format ideal laptime as "M'SS.mmm"
                    if idealLaptimeSeconds > 0
                        minutes = floor(idealLaptimeSeconds / 60);
                        remainingSeconds = idealLaptimeSeconds - (minutes * 60);
                        idealLaptimes(i) = sprintf('%d''%.3f', minutes, remainingSeconds);
                    else
                        idealLaptimes(i) = '0''0.000';
                    end
                    
                    % Get best lap time from laps data
                    bestLaptimeFormatted = '0''0.000';
                    if ~isempty(lapsData) && istable(lapsData)
                        if ismember('rider_name', lapsData.Properties.VariableNames) && ...
                           ismember('lap_time', lapsData.Properties.VariableNames)
                            riderNamesInLaps = lapsData.rider_name;
                            if iscell(riderNamesInLaps)
                                riderNamesInLaps = string(riderNamesInLaps);
                            end
                            riderMask = strcmpi(string(riderNamesInLaps), riderName);
                            if any(riderMask)
                                lapTimeData = lapsData.lap_time(riderMask);
                                % Parse lap times (format: "M'SS.mmm")
                                lapTimesSeconds = [];
                                for j = 1:length(lapTimeData)
                                    lapTimeStr = string(lapTimeData(j));
                                    if contains(lapTimeStr, '''')
                                        parts = split(lapTimeStr, '''');
                                        if length(parts) >= 2
                                            minutes = str2double(parts(1));
                                            secondsPart = str2double(parts(2));
                                            if ~isnan(minutes) && ~isnan(secondsPart)
                                                totalSeconds = minutes * 60 + secondsPart;
                                                lapTimesSeconds(end+1) = totalSeconds;
                                            end
                                        end
                                    else
                                        % Try as plain number
                                        secs = str2double(lapTimeStr);
                                        if ~isnan(secs)
                                            lapTimesSeconds(end+1) = secs;
                                        end
                                    end
                                end
                                if ~isempty(lapTimesSeconds)
                                    bestLaptimeSeconds = min(lapTimesSeconds);
                                    minutes = floor(bestLaptimeSeconds / 60);
                                    remainingSeconds = bestLaptimeSeconds - (minutes * 60);
                                    bestLaptimeFormatted = sprintf('%d''%.3f', minutes, remainingSeconds);
                                end
                            end
                        end
                    end
                    bestLaptimes(i) = bestLaptimeFormatted;
                end
                
                % Create summary table (Position first, then Rider_Name)
                summaryTable = table(positions, riderNames, idealLaptimes, bestLaptimes, ...
                    'VariableNames', {'Position', 'Rider_Name', 'Ideal_Laptime', 'Best_Laptime'});
                
                % Sort by position (ascending order, NaN values go to the end)
                % Create a sort key: NaN positions get a very high value for sorting
                sortKey = summaryTable.Position;
                sortKey(isnan(sortKey)) = Inf;
                [~, sortIdx] = sort(sortKey);
                summaryTable = summaryTable(sortIdx, :);
                
                % Update the summary table
                if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                    obj.SectorsSummaryTable.ColumnFormat = {};
                end
                obj.SectorsSummaryTable.Data = summaryTable;
                
                % Update highlighting for summary table
                obj.updateSectorsSummaryHighlighting();
                
            catch ME
                warning('RythmTab:UpdateSectorsSummaryTableError', ...
                    'Error updating sectors summary table: %s', ME.message);
                % Clear on error
                if isprop(obj.SectorsSummaryTable, 'ColumnFormat')
                    obj.SectorsSummaryTable.ColumnFormat = {};
                end
                obj.SectorsSummaryTable.Data = {};
            end
        end
        
        function clearSectorsSummaryTableStyles(obj)
            %CLEARSECTORSSUMMARYTABLESTYLES Clear all styles from sectors summary table
            % Uses StyleConfigurations to get styles and removes them by index
            if isempty(obj.SectorsSummaryTable) || ~isvalid(obj.SectorsSummaryTable)
                return;
            end
            
            % Get the number of styles using StyleConfigurations
            numStyles = size(obj.SectorsSummaryTable.StyleConfigurations, 1);
            
            % Remove each style by index, starting from the last one (reverse order)
            if numStyles > 0
                for i = numStyles:-1:1
                    try
                        removeStyle(obj.SectorsSummaryTable, i);
                    catch
                        % Ignore errors and continue
                    end
                end
            end
            
            % Re-apply center alignment
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.SectorsSummaryTable, centerStyle);
        end
        
        function updateSectorsSummaryHighlighting(obj)
            %UPDATESECTORSSUMMARYHIGHLIGHTING Update highlighting in sectors summary table based on selected riders
            % Highlights complete rows for selected riders
            if isempty(obj.SectorsSummaryTable.Data) || ~istable(obj.SectorsSummaryTable.Data)
                return;
            end
            
            % Clear existing styles first
            obj.clearSectorsSummaryTableStyles();
            
            % Get selected riders (both combo boxes)
            rider1 = obj.Sector1DropDown.Value;
            rider2 = obj.Sector2DropDown.Value;
            
            % Get table data
            summaryTableData = obj.SectorsSummaryTable.Data;
            if isempty(summaryTableData) || ~istable(summaryTableData)
                return;
            end
            
            % Get rider name column
            if ~ismember('Rider_Name', summaryTableData.Properties.VariableNames)
                return;
            end
            
            riderNameColData = summaryTableData.Rider_Name;
            if iscell(riderNameColData)
                riderNames = string(riderNameColData);
            elseif isstring(riderNameColData)
                riderNames = riderNameColData;
            else
                riderNames = string(riderNameColData);
            end
            
            % Replace missing/empty strings with empty string for proper comparison
            riderNames(ismissing(riderNames)) = "";
            
            numRows = height(summaryTableData);
            numCols = width(summaryTableData);
            
            % Highlight rider 1 in red
            if ~isempty(rider1) && ~isequal(rider1, '')
                mask1 = contains(riderNames, rider1, 'IgnoreCase', true);
                mask1 = mask1 & (strlength(riderNames) > 0);
                if any(mask1)
                    rows1 = find(mask1);
                    for r = 1:length(rows1)
                        rowIdx = rows1(r);
                        % Create style for entire row
                        redStyle = uistyle('BackgroundColor', [1 0 0], 'HorizontalAlignment', 'center');
                        % Create cell indices for all cells in the row
                        cellIndices = [repmat(rowIdx, numCols, 1), (1:numCols)'];
                        addStyle(obj.SectorsSummaryTable, redStyle, 'cell', cellIndices);
                    end
                end
            end
            
            % Highlight rider 2 in blue
            if ~isempty(rider2) && ~isequal(rider2, '')
                mask2 = contains(riderNames, rider2, 'IgnoreCase', true);
                mask2 = mask2 & (strlength(riderNames) > 0);
                if any(mask2)
                    rows2 = find(mask2);
                    for r = 1:length(rows2)
                        rowIdx = rows2(r);
                        % Create style for entire row
                        blueStyle = uistyle('BackgroundColor', [0.3 0.7 1], 'HorizontalAlignment', 'center');
                        % Create cell indices for all cells in the row
                        cellIndices = [repmat(rowIdx, numCols, 1), (1:numCols)'];
                        addStyle(obj.SectorsSummaryTable, blueStyle, 'cell', cellIndices);
                    end
                end
            end
        end
        
        function clearAllTableStyles(obj, tableObj)
            %CLEARALLTABLESTYLES Remove all styles from a table
            % Get all existing styles
            styleObjs = findall(tableObj, 'Type', 'uistyle');
            % Remove each style
            for i = 1:length(styleObjs)
                try
                    removeStyle(tableObj, styleObjs(i));
                catch
                    % If removeStyle fails, try delete
                    try
                        delete(styleObjs(i));
                    catch
                        % Ignore if both fail
                    end
                end
            end
        end
        
        function highlightZeroSpeedRows(obj, tableObj, tableData)
            %HIGHLIGHTZEROSPEEDROWS Highlight rows where speed column equals 0 in dark grey
            % Check if 'speed' column exists (case-insensitive)
            varNames = tableData.Properties.VariableNames;
            speedColIdx = find(contains(lower(varNames), 'speed'), 1);
            
            if isempty(speedColIdx)
                return; % No speed column, nothing to do
            end
            
            speedColName = varNames{speedColIdx};
            
            % Get speed column data
            speedData = tableData.(speedColName);
            
            % Find rows where speed = 0 (but not NaN)
            if isnumeric(speedData)
                zeroSpeedRows = find(speedData == 0 & ~isnan(speedData));
            else
                return; % Speed column is not numeric, skip
            end
            
            if ~isempty(zeroSpeedRows)
                % Create dark grey style
                darkGreyStyle = uistyle('BackgroundColor', [0.5 0.5 0.5]); % Dark grey
                
                % Get number of columns
                numCols = width(tableData);
                
                % Apply style to entire rows
                for r = 1:length(zeroSpeedRows)
                    rowIdx = zeroSpeedRows(r);
                    % Create N-by-2 matrix: [row, col] pairs for each cell in the row
                    cellIndices = [repmat(rowIdx, numCols, 1), (1:numCols)'];
                    addStyle(tableObj, darkGreyStyle, 'cell', cellIndices);
                end
            end
        end
        
        function resetTableBackgrounds(obj, tableObj, tableData)
            %RESETTABLEBACKGROUNDS Reset all cells to default white background with center alignment
            % Get table dimensions from the data
            numRows = height(tableData);
            numCols = width(tableData);
            
            if numRows > 0 && numCols > 0
                % Create a default style with white background and center alignment
                defaultStyle = uistyle('BackgroundColor', [1 1 1], 'HorizontalAlignment', 'center');
                % Apply to all cells
                allCells = zeros(numRows * numCols, 2);
                idx = 1;
                for r = 1:numRows
                    for c = 1:numCols
                        allCells(idx, :) = [r, c];
                        idx = idx + 1;
                    end
                end
                addStyle(tableObj, defaultStyle, 'cell', allCells);
            end
        end
        
        function ensureLapsTableColumnWidths(obj)
            %ENSURELAPSTABLECOLUMNWIDTHS Ensure column widths fill table width for pre-selected riders
            % This is called after UI renders to fix column widths for pre-selected riders
            % Call it the same way as in updateLapsTable
            drawnow;
            if isvalid(obj.LapsTable1) && ~isempty(obj.LapsTable1.Data)
                obj.fitColumnsToTableWidth(obj.LapsTable1);
            end
            if isvalid(obj.LapsTable2) && ~isempty(obj.LapsTable2.Data)
                obj.fitColumnsToTableWidth(obj.LapsTable2);
            end
            % Also ensure summary tables have correct column widths
            if isvalid(obj.LapsSummaryTable1) && ~isempty(obj.LapsSummaryTable1.Data)
                obj.fitColumnsToTableWidth(obj.LapsSummaryTable1);
            end
            if isvalid(obj.LapsSummaryTable2) && ~isempty(obj.LapsSummaryTable2.Data)
                obj.fitColumnsToTableWidth(obj.LapsSummaryTable2);
            end
        end
        
        function scrollRidersTableToTop(obj)
            %SCROLLRIDERSTABLETOTOP Scroll the riders table to the top
            % No longer needed - table is directly in grid layout (no scrollable panel)
            % This function is kept for compatibility but does nothing
        end
        
        function updateSpeedsTable(obj)
            %UPDATESPEEDSTABLE Update speeds table with riders sorted by fastest speed
            % Uses motogp_analysis_laps.csv speed column to get top speeds per rider
            try
                % Load laps CSV directly
                [csvDir, ~, ~] = fileparts(obj.CsvPath);
                lapsCsvPath = fullfile(csvDir, 'motogp_analysis_laps.csv');
                
                if ~isfile(lapsCsvPath)
                    obj.SpeedsTable.Data = {};
                    obj.SpeedsTable.ColumnName = {};
                    return;
                end
                
                lapsTable = readtable(lapsCsvPath);
                
                if isempty(lapsTable) || ~istable(lapsTable)
                    obj.SpeedsTable.Data = {};
                    obj.SpeedsTable.ColumnName = {};
                    return;
                end
                
                % Find the speed column
                varNames = lapsTable.Properties.VariableNames;
                speedColName = '';
                riderNameColName = '';
                
                % First, try to use column 15 directly (same as updateLapsTable)
                if length(varNames) >= 15
                    speedColName = varNames{15};
                end
                
                % If column 15 doesn't exist or doesn't contain 'speed', try to find by name
                if isempty(speedColName) || ~contains(lower(speedColName), 'speed')
                    % Try to find exact match for 'speed' (case insensitive)
                    for i = 1:length(varNames)
                        if strcmpi(varNames{i}, 'speed')
                            speedColName = varNames{i};
                            break;
                        end
                    end
                    
                    % If still not found, look for any column containing 'speed' but not 'max_speed' or 'top_speed'
                    if isempty(speedColName)
                        for i = 1:length(varNames)
                            varNameLower = lower(varNames{i});
                            if contains(varNameLower, 'speed') && ...
                               ~contains(varNameLower, 'max_speed') && ...
                               ~contains(varNameLower, 'top_speed')
                                speedColName = varNames{i};
                                break; % Take the first match
                            end
                        end
                    end
                end
                
                % Find rider name column - look for rider_name or rider name
                for i = 1:length(varNames)
                    varNameLower = lower(varNames{i});
                    if contains(varNameLower, 'rider_name') || ...
                       (contains(varNameLower, 'rider') && contains(varNameLower, 'name'))
                        riderNameColName = varNames{i};
                        break;
                    end
                end
                
                if isempty(speedColName) || isempty(riderNameColName)
                    obj.SpeedsTable.Data = {};
                    obj.SpeedsTable.ColumnName = {};
                    return;
                end
                
                % Get unique riders
                riderNamesRaw = lapsTable.(riderNameColName);
                if iscell(riderNamesRaw)
                    riderNamesRaw = string(riderNamesRaw);
                end
                riderNamesRaw = string(riderNamesRaw);
                uniqueRiders = unique(riderNamesRaw, 'stable');
                
                % For each rider, extract all speed values, get top 5 speeds
                speedsData = cell(length(uniqueRiders), 12); % Position, Rider, Speed1-5, Average, Max_Speed, Max-Avg, Range, SlipstreamLikelihood
                
                for i = 1:length(uniqueRiders)
                    rider = uniqueRiders(i);
                    riderMask = strcmp(riderNamesRaw, rider);
                    riderSpeeds = lapsTable.(speedColName)(riderMask);
                    
                    % Convert to numeric and filter out NaN and zero values
                    if isnumeric(riderSpeeds)
                        validSpeeds = riderSpeeds(~isnan(riderSpeeds) & riderSpeeds > 0);
                    else
                        riderSpeeds = double(riderSpeeds);
                        validSpeeds = riderSpeeds(~isnan(riderSpeeds) & riderSpeeds > 0);
                    end
                    
                    if ~isempty(validSpeeds)
                        % Sort speeds in descending order (fastest first)
                        sortedSpeeds = sort(validSpeeds, 'descend');
                        
                        % Get top 5 speeds (or fewer if less than 5 available)
                        top5Speeds = sortedSpeeds(1:min(5, length(sortedSpeeds)));
                        maxSpeed = sortedSpeeds(1); % Overall fastest speed
                        
                        % Reverse the order so Speed5 is the fastest (Speed1 is slowest of the 5)
                        top5SpeedsReversed = top5Speeds(end:-1:1);
                        
                        % Fill speedsData
                        speedsData{i, 1} = i; % Position (will be updated after sorting)
                        speedsData{i, 2} = char(rider); % Rider name
                        % Fill top 5 speeds in reversed order (Speed5 = fastest, Speed1 = slowest of top 5)
                        for j = 1:5
                            if j <= length(top5SpeedsReversed)
                                speedsData{i, 2+j} = top5SpeedsReversed(j);
                            else
                                speedsData{i, 2+j} = NaN;
                            end
                        end
                        % Calculate average of Speed1-5
                        speedValues = [speedsData{i, 3}; speedsData{i, 4}; speedsData{i, 5}; speedsData{i, 6}; speedsData{i, 7}];
                        validSpeedValues = speedValues(~isnan(speedValues));
                        if ~isempty(validSpeedValues)
                            speedsData{i, 8} = mean(validSpeedValues); % Average
                        else
                            speedsData{i, 8} = NaN; % Average
                        end
                        speedsData{i, 9} = maxSpeed; % Max speed (overall fastest)
                        
                        % Calculate Max-Avg (Max_Speed - Average)
                        speedsData{i, 10} = maxSpeed - speedsData{i, 8}; % Max-Avg
                        
                        % Calculate Range (Max of 5 speeds - Min of 5 speeds)
                        % top5SpeedsReversed has Speed1 (slowest) to Speed5 (fastest)
                        % So max is Speed5 (last element) and min is Speed1 (first element)
                        validTop5Speeds = top5SpeedsReversed(~isnan(top5SpeedsReversed));
                        if ~isempty(validTop5Speeds) && length(validTop5Speeds) > 1
                            maxOf5 = max(validTop5Speeds); % This is Speed5
                            minOf5 = min(validTop5Speeds); % This is Speed1
                            speedsData{i, 11} = maxOf5 - minOf5; % Range
                        elseif length(validTop5Speeds) == 1
                            speedsData{i, 11} = 0; % Only one speed, range is 0
                        else
                            speedsData{i, 11} = NaN; % Range
                        end
                        
                        % SlipstreamLikelihood will be calculated after we have all data
                        speedsData{i, 12} = NaN; % Placeholder for SlipstreamLikelihood
                    else
                        speedsData{i, 1} = i;
                        speedsData{i, 2} = char(rider);
                        for j = 3:12
                            speedsData{i, j} = NaN;
                        end
                    end
                end
                
                % Calculate session statistics for SlipstreamLikelihood scoring
                % Get all valid averages and max speeds
                allAverages = [];
                allMaxSpeeds = [];
                for i = 1:length(uniqueRiders)
                    if ~isnan(speedsData{i, 8}) && ~isnan(speedsData{i, 9})
                        allAverages(end+1) = speedsData{i, 8};
                        allMaxSpeeds(end+1) = speedsData{i, 9};
                    end
                end
                sessionAvg = mean(allAverages);
                sessionTopSpeed = max(allMaxSpeeds);
                
                % Calculate SlipstreamLikelihood score for each rider
                for i = 1:length(uniqueRiders)
                    if ~isnan(speedsData{i, 8}) && ~isnan(speedsData{i, 9}) && ~isnan(speedsData{i, 10})
                        score = 0;
                        maxAvgDelta = speedsData{i, 10}; % Max-Avg
                        range = speedsData{i, 11}; % Range
                        riderAvg = speedsData{i, 8}; % Average
                        riderMax = speedsData{i, 9}; % Max_Speed
                        
                        % Condition 1: Δ(Max−Avg) ≥ 2.0 km/h
                        if maxAvgDelta >= 2.0
                            score = score + 1;
                        end
                        
                        % Condition 2: Range ≥ 2.5 km/h
                        if ~isnan(range) && range >= 2.5
                            score = score + 1;
                        end
                        
                        % Condition 3: Max speed within ~1 km/h of session top speed
                        if abs(riderMax - sessionTopSpeed) <= 1.0
                            score = score + 1;
                        end
                        
                        % Condition 4: Rider avg below session avg but max very high
                        if riderAvg < sessionAvg && riderMax >= sessionTopSpeed - 1.0
                            score = score + 1;
                        end
                        
                        speedsData{i, 12} = score; % SlipstreamLikelihood
                    else
                        speedsData{i, 12} = NaN;
                    end
                end
                
                % Create temporary table to sort by fastest speed
                % Convert speed columns to numeric arrays first
                positionCol = cell2mat(speedsData(:, 1));
                riderCol = speedsData(:, 2);
                speed1Col = cell2mat(speedsData(:, 3));
                speed2Col = cell2mat(speedsData(:, 4));
                speed3Col = cell2mat(speedsData(:, 5));
                speed4Col = cell2mat(speedsData(:, 6));
                speed5Col = cell2mat(speedsData(:, 7));
                averageCol = cell2mat(speedsData(:, 8));
                fastestSpeedCol = cell2mat(speedsData(:, 9));
                maxAvgCol = cell2mat(speedsData(:, 10));
                rangeCol = cell2mat(speedsData(:, 11));
                slipstreamLikelihoodCol = cell2mat(speedsData(:, 12));
                
                tempTable = table(positionCol, riderCol, speed1Col, speed2Col, speed3Col, speed4Col, speed5Col, averageCol, fastestSpeedCol, maxAvgCol, rangeCol, slipstreamLikelihoodCol, ...
                    'VariableNames', {'Position', 'Rider', 'Speed1', 'Speed2', 'Speed3', 'Speed4', 'Speed5', 'Average', 'Max_Speed', 'Max-Avg', 'Range', 'SlipstreamLikelihood'});
                
                % Sort by max speed (descending)
                validMask = ~isnan(fastestSpeedCol);
                [~, sortIdx] = sort(fastestSpeedCol(validMask), 'descend');
                % Reconstruct full sort index
                validIndices = find(validMask);
                invalidIndices = find(~validMask);
                fullSortIdx = [validIndices(sortIdx); invalidIndices'];
                sortedTable = tempTable(fullSortIdx, :);
                
                % Update position column based on sorted order
                sortedTable.Position = (1:height(sortedTable))';
                
                % Store SlipstreamLikelihood scores before formatting (for styling later)
                slipstreamScores = sortedTable.SlipstreamLikelihood;
                
                % Format speed columns, average, Max-Avg, and Range to 1 decimal place (convert numeric to formatted strings)
                for colIdx = 3:11 % Speed1-5, Average, Max_Speed, Max-Avg, Range
                    colName = sortedTable.Properties.VariableNames{colIdx};
                    colData = sortedTable.(colName);
                    formattedCol = cell(height(sortedTable), 1);
                    for r = 1:height(sortedTable)
                        if isnan(colData(r))
                            formattedCol{r} = '';
                        else
                            formattedCol{r} = sprintf('%.1f', colData(r));
                        end
                    end
                    sortedTable.(colName) = formattedCol;
                end
                
                % Format SlipstreamLikelihood as text descriptions with icons
                colData = sortedTable.SlipstreamLikelihood;
                formattedCol = cell(height(sortedTable), 1);
                for r = 1:height(sortedTable)
                    if isnan(colData(r))
                        formattedCol{r} = '';
                    else
                        score = colData(r);
                        if score <= 1
                            formattedCol{r} = '🟢 Unlikely';
                        elseif score == 2
                            formattedCol{r} = '🟠 Possible';
                        elseif score >= 3
                            formattedCol{r} = '🔴 Very Likely';
                        else
                            formattedCol{r} = '';
                        end
                    end
                end
                sortedTable.SlipstreamLikelihood = formattedCol;
                
                % Update the table
                if isprop(obj.SpeedsTable, 'ColumnFormat')
                    obj.SpeedsTable.ColumnFormat = {};
                end
                obj.SpeedsTable.Data = sortedTable;
                obj.SpeedsTable.ColumnName = {'Position', 'Rider', 'Speed1', 'Speed2', 'Speed3', 'Speed4', 'Speed5', 'Average', 'Max_Speed', 'Max-Avg', 'Range', 'SlipstreamLikelihood'};
                
                % Apply background colors to SlipstreamLikelihood column based on score
                slipstreamColIdx = find(strcmp(sortedTable.Properties.VariableNames, 'SlipstreamLikelihood'));
                if ~isempty(slipstreamColIdx)
                    for r = 1:height(sortedTable)
                        if ~isnan(slipstreamScores(r))
                            score = slipstreamScores(r);
                            if score <= 1
                                % Green background for Unlikely
                                style = uistyle('BackgroundColor', [0.7 1.0 0.7], 'HorizontalAlignment', 'center');
                            elseif score == 2
                                % Orange background for Possible
                                style = uistyle('BackgroundColor', [1.0 0.8 0.5], 'HorizontalAlignment', 'center');
                            elseif score >= 3
                                % Red background for Very Likely
                                style = uistyle('BackgroundColor', [1.0 0.7 0.7], 'HorizontalAlignment', 'center');
                            else
                                style = uistyle('HorizontalAlignment', 'center');
                            end
                            addStyle(obj.SpeedsTable, style, 'cell', [r, slipstreamColIdx]);
                        end
                    end
                end
                
                % Apply heatmap to Speed1-5 columns (together) and Max_Speed column
                obj.applySpeedsHeatmap(sortedTable, slipstreamScores);
                
                % Update speeds graph
                obj.updateSpeedsGraph(sortedTable, slipstreamScores);
                
                % Set column widths to fill the table width (Max-Avg and Range columns will be hidden)
                drawnow;
                obj.fitColumnsToTableWidth(obj.SpeedsTable);
                
            catch ME
                warning('RythmTab:UpdateSpeedsTableError', ...
                    'Error updating speeds table: %s', ME.message);
                obj.SpeedsTable.Data = {};
                obj.SpeedsTable.ColumnName = {};
            end
        end
        
        function applySpeedsHeatmap(obj, sortedTable, slipstreamScores)
            %APPLYSPEEDSHEATMAP Apply heatmap to Speed1-5 columns (together) and Max_Speed column
            % Uses same color scheme as laps tables: light green to dark green at 25% transparency
            
            try
                varNames = sortedTable.Properties.VariableNames;
                
                % Find column indices
                speed1Idx = find(strcmp(varNames, 'Speed1'), 1);
                speed5Idx = find(strcmp(varNames, 'Speed5'), 1);
                maxSpeedIdx = find(strcmp(varNames, 'Max_Speed'), 1);
                
                if isempty(speed1Idx) || isempty(speed5Idx) || isempty(maxSpeedIdx)
                    return;
                end
                
                numRows = height(sortedTable);
                if numRows <= 0
                    return;
                end
                
                % For Speed1-5: treat them as a group and find min/max across all 5 columns
                % Extract numeric values from Speed1-5 (they are formatted as strings)
                allSpeedValues = [];
                speedColIndices = speed1Idx:speed5Idx;
                
                for colIdx = speedColIndices
                    colName = varNames{colIdx};
                    colData = sortedTable.(colName);
                    % Convert from cell array of strings to numeric
                    numericData = zeros(numRows, 1);
                    for r = 1:numRows
                        if iscell(colData)
                            valStr = colData{r};
                            if ischar(valStr) || isstring(valStr)
                                numericData(r) = str2double(valStr);
                            else
                                numericData(r) = valStr;
                            end
                        elseif isnumeric(colData)
                            numericData(r) = colData(r);
                        end
                    end
                    allSpeedValues = [allSpeedValues; numericData(~isnan(numericData) & numericData > 0)];
                end
                
                if isempty(allSpeedValues)
                    return;
                end
                
                minSpeed = min(allSpeedValues);
                maxSpeed = max(allSpeedValues);
                
                % For Max_Speed: extract numeric values
                maxSpeedData = sortedTable.Max_Speed;
                maxSpeedNumeric = zeros(numRows, 1);
                for r = 1:numRows
                    if iscell(maxSpeedData)
                        valStr = maxSpeedData{r};
                        if ischar(valStr) || isstring(valStr)
                            maxSpeedNumeric(r) = str2double(valStr);
                        else
                            maxSpeedNumeric(r) = valStr;
                        end
                    elseif isnumeric(maxSpeedData)
                        maxSpeedNumeric(r) = maxSpeedData(r);
                    end
                end
                
                validMaxSpeeds = maxSpeedNumeric(~isnan(maxSpeedNumeric) & maxSpeedNumeric > 0);
                if isempty(validMaxSpeeds)
                    return;
                end
                
                minMaxSpeed = min(validMaxSpeeds);
                maxMaxSpeed = max(validMaxSpeeds);
                
                % 2-color gradient: Light Green -> Dark Green at 25% transparency
                baseLightGreen = [0.6 1.0 0.6];   % Light green
                baseDarkGreen = [0.0 0.5 0.0];    % Dark green
                white = [1.0 1.0 1.0];            % White for blending
                
                % Apply 25% transparency (25% = 0.25 * color + 0.75 * white)
                lightGreenColor = 0.25 * baseLightGreen + 0.75 * white;
                darkGreenColor = 0.25 * baseDarkGreen + 0.75 * white;
                
                % Apply heatmap to Speed1-5 columns (as a group)
                if minSpeed < maxSpeed
                    for colIdx = speedColIndices
                        colName = varNames{colIdx};
                        colData = sortedTable.(colName);
                        for r = 1:numRows
                            % Convert to numeric
                            if iscell(colData)
                                valStr = colData{r};
                                if ischar(valStr) || isstring(valStr)
                                    val = str2double(valStr);
                                else
                                    val = valStr;
                                end
                            elseif isnumeric(colData)
                                val = colData(r);
                            else
                                continue;
                            end
                            
                            if ~isnan(val) && val > 0
                                % Calculate normalized value [0, 1] based on group min/max
                                normalizedVal = (val - minSpeed) / (maxSpeed - minSpeed);
                                normalizedVal = max(0, min(1, normalizedVal)); % Clamp to [0, 1]
                                
                                % For speeds, higher is better, so reverse (higher = lighter green)
                                normalizedVal = 1 - normalizedVal;
                                
                                % Interpolate between light green and dark green
                                cellColor = lightGreenColor * (1 - normalizedVal) + darkGreenColor * normalizedVal;
                                
                                % Create style for this cell
                                heatmapStyle = uistyle('BackgroundColor', cellColor, 'HorizontalAlignment', 'center');
                                addStyle(obj.SpeedsTable, heatmapStyle, 'cell', [r, colIdx]);
                            end
                        end
                    end
                end
                
                % Apply heatmap to Max_Speed column
                if minMaxSpeed < maxMaxSpeed
                    for r = 1:numRows
                        val = maxSpeedNumeric(r);
                        if ~isnan(val) && val > 0
                            % Calculate normalized value [0, 1]
                            normalizedVal = (val - minMaxSpeed) / (maxMaxSpeed - minMaxSpeed);
                            normalizedVal = max(0, min(1, normalizedVal)); % Clamp to [0, 1]
                            
                            % For speeds, higher is better, so reverse (higher = lighter green)
                            normalizedVal = 1 - normalizedVal;
                            
                            % Interpolate between light green and dark green
                            cellColor = lightGreenColor * (1 - normalizedVal) + darkGreenColor * normalizedVal;
                            
                            % Create style for this cell
                            heatmapStyle = uistyle('BackgroundColor', cellColor, 'HorizontalAlignment', 'center');
                            addStyle(obj.SpeedsTable, heatmapStyle, 'cell', [r, maxSpeedIdx]);
                        end
                    end
                end
                
            catch ME
                warning('RythmTab:ApplySpeedsHeatmapError', ...
                    'Error applying speeds heatmap: %s', ME.message);
            end
        end
        
        function updateSpeedsGraph(obj, sortedTable, slipstreamScores)
            %UPDATESPEEDSGRAPH Update graph showing riders vs Average and Max_Speed
            
            try
                if isempty(sortedTable) || height(sortedTable) == 0
                    cla(obj.SpeedsAxes);
                    return;
                end
                
                % Extract rider names, Average, and Max_Speed
                riderNames = sortedTable.Rider;
                averageData = sortedTable.Average;
                maxSpeedData = sortedTable.Max_Speed;
                
                % Convert to numeric arrays
                numRiders = height(sortedTable);
                riders = cell(numRiders, 1);
                averages = zeros(numRiders, 1);
                maxSpeeds = zeros(numRiders, 1);
                
                for r = 1:numRiders
                    if iscell(riderNames)
                        riders{r} = char(riderNames{r});
                    elseif isstring(riderNames)
                        riders{r} = char(riderNames(r));
                    else
                        riders{r} = char(riderNames(r));
                    end
                    
                    % Convert Average to numeric
                    if iscell(averageData)
                        avgStr = averageData{r};
                        if ischar(avgStr) || isstring(avgStr)
                            averages(r) = str2double(avgStr);
                        else
                            averages(r) = avgStr;
                        end
                    elseif isnumeric(averageData)
                        averages(r) = averageData(r);
                    end
                    
                    % Convert Max_Speed to numeric
                    if iscell(maxSpeedData)
                        maxStr = maxSpeedData{r};
                        if ischar(maxStr) || isstring(maxStr)
                            maxSpeeds(r) = str2double(maxStr);
                        else
                            maxSpeeds(r) = maxStr;
                        end
                    elseif isnumeric(maxSpeedData)
                        maxSpeeds(r) = maxSpeedData(r);
                    end
                end
                
                % Filter out NaN values
                validMask = ~isnan(averages) & ~isnan(maxSpeeds);
                if sum(validMask) == 0
                    cla(obj.SpeedsAxes);
                    return;
                end
                
                validRiders = riders(validMask);
                validAverages = averages(validMask);
                validMaxSpeeds = maxSpeeds(validMask);
                
                % Clear axes
                cla(obj.SpeedsAxes);
                
                % Create x positions for riders
                xPos = 1:length(validRiders);
                
                % Calculate polynomial regression for Average (order 2 for curved fit)
                if length(xPos) > 2
                    % Use polyfit to get polynomial regression coefficients (order 2 = quadratic)
                    p = polyfit(xPos, validAverages, 2); % 2nd degree polynomial (quadratic)
                    yFitAverage = polyval(p, xPos); % Calculate fitted values
                elseif length(xPos) > 1
                    % Fall back to linear if not enough points
                    p = polyfit(xPos, validAverages, 1);
                    yFitAverage = polyval(p, xPos);
                else
                    yFitAverage = validAverages; % If only one point, use the value itself
                end
                
                % Calculate polynomial regression for Max Speed (order 2 for curved fit)
                if length(xPos) > 2
                    % Use polyfit to get polynomial regression coefficients (order 2 = quadratic)
                    p = polyfit(xPos, validMaxSpeeds, 2); % 2nd degree polynomial (quadratic)
                    yFitMaxSpeed = polyval(p, xPos); % Calculate fitted values
                elseif length(xPos) > 1
                    % Fall back to linear if not enough points
                    p = polyfit(xPos, validMaxSpeeds, 1);
                    yFitMaxSpeed = polyval(p, xPos);
                else
                    yFitMaxSpeed = validMaxSpeeds; % If only one point, use the value itself
                end
                
                % Plot Average and Max_Speed
                hold(obj.SpeedsAxes, 'on');
                plot(obj.SpeedsAxes, xPos, validAverages, '-o', 'Color', [0.2 0.6 1.0], 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Average');
                plot(obj.SpeedsAxes, xPos, validMaxSpeeds, '-s', 'Color', [1.0 0.3 0.3], 'LineWidth', 2, 'MarkerSize', 6, 'DisplayName', 'Max Speed');
                % Plot polynomial regression lines
                plot(obj.SpeedsAxes, xPos, yFitAverage, '--', 'Color', [0.2 0.6 1.0], 'LineWidth', 1.5, 'DisplayName', 'Average Trend');
                plot(obj.SpeedsAxes, xPos, yFitMaxSpeed, '--', 'Color', [1.0 0.3 0.3], 'LineWidth', 1.5, 'DisplayName', 'Max Speed Trend');
                hold(obj.SpeedsAxes, 'off');
                
                % Set x-axis labels to rider names
                obj.SpeedsAxes.XTick = xPos;
                obj.SpeedsAxes.XTickLabel = validRiders;
                obj.SpeedsAxes.XTickLabelRotation = 45;
                obj.SpeedsAxes.XLim = [0.5, length(validRiders) + 0.5];
                
                % Set labels
                obj.SpeedsAxes.XLabel.String = 'Riders';
                obj.SpeedsAxes.YLabel.String = 'Speed (km/h)';
                obj.SpeedsAxes.Title.String = 'Average vs Max Speed';
                
                % Add legend
                legend(obj.SpeedsAxes, 'show', 'Location', 'best', 'TextColor', [1 1 1], 'Color', [0.3 0.3 0.3]);
                
                % Refresh
                drawnow;
                
            catch ME
                warning('RythmTab:UpdateSpeedsGraphError', ...
                    'Error updating speeds graph: %s', ME.message);
            end
        end
        
        function resizeSummaryTable(obj, summaryPanel, tableNum)
            %RESIZESUMMARYTABLE Resize summary table to fill its parent panel
            if ~isvalid(summaryPanel)
                return;
            end
            
            panelPos = summaryPanel.Position;
            panelWidth = panelPos(3);
            panelHeight = panelPos(4);
            
            % Position table to fill panel (with 1 pixel margin on each side)
            tablePos = [1 1 max(1, panelWidth - 2) max(1, panelHeight - 2)];
            
            if tableNum == 1 && isvalid(obj.LapsSummaryTable1)
                obj.LapsSummaryTable1.Position = tablePos;
            elseif tableNum == 2 && isvalid(obj.LapsSummaryTable2)
                obj.LapsSummaryTable2.Position = tablePos;
            end
        end
    end
end

