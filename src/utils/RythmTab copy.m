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
        
        % Laps tables
        LapsTable1
        LapsTable2
        LapsTable1DropDown
        LapsTable2DropDown
        
        % Sectors table
        SectorsTable
        
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
            
            % Create first tab: Main Riders Table
            ridersTab = uitab(nestedTabGroup);
            ridersTab.Title = 'Riders';
            ridersTab.BackgroundColor = [0.3 0.3 0.3];
            
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
            
            % Create scrollable panel for main table
            scrollPanel = uipanel(ridersGrid);
            scrollPanel.Layout.Row = 2;
            scrollPanel.Layout.Column = 1;
            scrollPanel.BackgroundColor = [0.3 0.3 0.3];
            scrollPanel.Scrollable = 'on';
            
            % Create table with fixed height for 28 rows
            obj.RidersTable = uitable(scrollPanel);
            obj.RidersTable.Position = [10 10 1113 700]; % Fixed height for 28 rows
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
            
            % Create scrollable panel for sectors table
            sectorsScrollPanel = uipanel(sectorsTab);
            sectorsScrollPanel.Position = [1 1 1133 632];
            sectorsScrollPanel.BackgroundColor = [0.3 0.3 0.3];
            sectorsScrollPanel.Scrollable = 'on';
            
            % Create sectors table
            obj.SectorsTable = uitable(sectorsScrollPanel);
            obj.SectorsTable.Position = [10 10 1113 700];
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
        end
        
        function createLapsTableSection(obj, rowNum, colNum, tableNum)
            %CREATELAPSTABLESECTION Create a laps table section with combo box
            % Create panel for this table section
            tablePanel = uipanel(obj.MainGrid);
            tablePanel.Layout.Row = rowNum;
            tablePanel.Layout.Column = colNum;
            tablePanel.BackgroundColor = [0.3 0.3 0.3];
            
            % Create grid for combo box and table
            sectionGrid = uigridlayout(tablePanel, [2 1]);
            sectionGrid.RowHeight = {'fit', '1x'};
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
            
            % Table panel
            tableScrollPanel = uipanel(sectionGrid);
            tableScrollPanel.Layout.Row = 2;
            tableScrollPanel.Layout.Column = 1;
            tableScrollPanel.BackgroundColor = [0.3 0.3 0.3];
            tableScrollPanel.Scrollable = 'on';
            
            % Create table
            if tableNum == 1
                obj.LapsTable1 = uitable(tableScrollPanel);
                obj.LapsTable1.Position = [10 10 1113 200];
                obj.LapsTable1.ColumnEditable = false;
                obj.LapsTable1.RowName = [];
                obj.LapsTable1.ColumnWidth = 'auto';
                obj.LapsTable1.Data = {};
                obj.LapsTable1.ColumnName = {};
            else
                obj.LapsTable2 = uitable(tableScrollPanel);
                obj.LapsTable2.Position = [10 10 1113 200];
                obj.LapsTable2.ColumnEditable = false;
                obj.LapsTable2.RowName = [];
                obj.LapsTable2.ColumnWidth = 'auto';
                obj.LapsTable2.Data = {};
                obj.LapsTable2.ColumnName = {};
            end
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
                
                % Set fixed table height for 28 rows (approximately 25px per row)
                rowHeight = 25;
                tableHeight = 28 * rowHeight;
                currentPos = obj.RidersTable.Position;
                obj.RidersTable.Position = [currentPos(1), currentPos(2), currentPos(3), tableHeight];
                
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
            end
            if ~isempty(obj.LapsTable2DropDown)
                obj.LapsTable2DropDown.Items = [{''}; riderNames];
            end
            
            % No pre-selected riders - start with empty selections
            obj.Rider1DropDown.Value = '';
            obj.Rider2DropDown.Value = '';
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
                    redStyle = uistyle('BackgroundColor', [1 0.5 0.5]); % Light red
                    rows1 = find(mask1);
                    numCols = width(obj.TableData);
                    for r = 1:length(rows1)
                        % Create N-by-2 matrix: [row, col] pairs for each cell in the row
                        cellIndices = [repmat(rows1(r), numCols, 1), (1:numCols)'];
                        addStyle(obj.RidersTable, redStyle, 'cell', cellIndices);
                    end
                end
            end
            
            % Highlight ONLY the currently selected rider 2 in light blue
            if ~isempty(rider2) && ~isequal(rider2, '')
                mask2 = contains(riderNames, rider2, 'IgnoreCase', true);
                if any(mask2)
                    blueStyle = uistyle('BackgroundColor', [0.5 0.7 1]); % Light blue
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
        
        function updateLapsTable(obj, tableNum, riderName)
            %UPDATELAPSTABLE Update laps table with filtered data for selected rider
            if isempty(obj.LapsData) || isempty(riderName) || isequal(riderName, '')
                % Clear table if no rider selected or no data
                if tableNum == 1
                    obj.LapsTable1.Data = {};
                    obj.LapsTable1.ColumnName = {};
                else
                    obj.LapsTable2.Data = {};
                    obj.LapsTable2.ColumnName = {};
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
                else
                    obj.LapsTable2.Data = {};
                    obj.LapsTable2.ColumnName = {};
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
                    
                    % Highlight fastest sector times in red
                    obj.highlightFastestSectors(obj.LapsTable1, T_display, [1 0 0]); % Red
                else
                    % First, clear all existing styles
                    obj.clearAllTableStyles(obj.LapsTable2);
                    
                    % Set the new data
                    % Clear ColumnFormat to avoid warnings when using table Data
                    if isprop(obj.LapsTable2, 'ColumnFormat')
                        obj.LapsTable2.ColumnFormat = {};
                    end
                    obj.LapsTable2.Data = T_display;
                    obj.LapsTable2.ColumnName = colNames;
                    
                    % Reset all cells to default white background with center alignment
                    obj.resetTableBackgrounds(obj.LapsTable2, T_display);
                    
                    % Highlight fastest sector times in light blue
                    obj.highlightFastestSectors(obj.LapsTable2, T_display, [0.5 0.7 1]); % Light blue
                end
            end
        end
        
        function highlightFastestSectors(obj, tableObj, tableData, highlightColor)
            %HIGHLIGHTFASTESTSECTORS Highlight the fastest (lowest) value in each sector column
            % Ignores first row when finding fastest sectors
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
            
            % For each sector column, find the row with the minimum value
            numRows = height(tableData);
            
            % Only process if we have more than 1 row (need rows beyond first to highlight)
            if numRows <= 1
                return;
            end
            
            for i = 1:length(sectorCols)
                colName = sectorCols{i};
                colIndex = sectorIndices(i);
                
                % Get column data
                colData = tableData.(colName);
                
                % Convert to numeric if needed and filter out zeros (which were NaN replacements)
                if isnumeric(colData)
                    % Create a copy for finding minimum, excluding first row only
                    validData = colData;
                    validData(validData == 0) = NaN; % Treat zeros as invalid
                    
                    % Exclude first row (index 1) only
                    validDataForMin = validData;
                    validDataForMin(1) = NaN; % Ignore first row
                    
                    % Find minimum value (excluding first row and zeros/NaN)
                    [minVal, minRow] = min(validDataForMin);
                    
                    % Only highlight if we found a valid minimum and it's not the first row
                    if ~isnan(minVal) && minRow > 1
                        % Create highlight style
                        highlightStyle = uistyle('BackgroundColor', highlightColor, 'HorizontalAlignment', 'center');
                        % Apply to the cell at [minRow, colIndex]
                        addStyle(tableObj, highlightStyle, 'cell', [minRow, colIndex]);
                    end
                end
            end
        end
        
        function updateSectorsTable(obj)
            %UPDATESECTORSTABLE Update sectors table with sorted rider positions per sector
            try
                if isempty(obj.SectorsData) || ~isa(obj.SectorsData, 'table')
                    % Set empty table with column headers
                    obj.SectorsTable.Data = cell(0, 8);
                    obj.SectorsTable.ColumnName = {'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
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
                    obj.SectorsTable.Data = cell(0, 8);
                    obj.SectorsTable.ColumnName = {'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
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
                obj.SectorsTable.Data = cell(0, 8);
                obj.SectorsTable.ColumnName = {'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                               'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                               'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                               'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
                return;
            end
            
            % Create the combined table using a table object (similar to LapsTable)
            % Initialize columns as string arrays for names and numeric arrays for times
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
            
            % Create table object
            combinedTable = table(sector1Names, sector1Times, ...
                                  sector2Names, sector2Times, ...
                                  sector3Names, sector3Times, ...
                                  sector4Names, sector4Times);
            
            % Update the table
            % Clear ColumnFormat to avoid warnings when using table Data
            if isprop(obj.SectorsTable, 'ColumnFormat')
                obj.SectorsTable.ColumnFormat = {};
            end
            obj.SectorsTable.Data = combinedTable;
            obj.SectorsTable.ColumnName = {'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                           'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                           'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                           'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
            
            % Force table refresh
            drawnow;
            
                % Apply center alignment (if not already applied)
                styleObjs = findall(obj.SectorsTable, 'Type', 'uistyle');
                if isempty(styleObjs)
                    centerStyle = uistyle('HorizontalAlignment', 'center');
                    addStyle(obj.SectorsTable, centerStyle);
                end
            catch ME
                warning('RythmTab:UpdateSectorsTableError', ...
                    'Error updating sectors table: %s', ME.message);
                % Set empty table with column headers on error
                obj.SectorsTable.Data = cell(0, 8);
                obj.SectorsTable.ColumnName = {'Sector 1 Rider Name', 'Sector 1 Rider Laptime', ...
                                               'Sector 2 Rider Name', 'Sector 2 Rider Laptime', ...
                                               'Sector 3 Rider Name', 'Sector 3 Rider Laptime', ...
                                               'Sector 4 Rider Name', 'Sector 4 Rider Laptime'};
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
    end
end

