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
        
        % Data
        CsvPath
        Data table
        TableData table
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
            
            % Create main grid layout
            mainGrid = uigridlayout(obj.Tab, [2 1]);
            mainGrid.RowHeight = {'fit', '1x'};
            mainGrid.ColumnWidth = {'1x'};
            mainGrid.Padding = [10 10 10 10];
            mainGrid.BackgroundColor = [0.3 0.3 0.3]; % Dark grey background
            
            % Create combo boxes panel
            comboPanel = uipanel(mainGrid);
            comboPanel.Layout.Row = 1;
            comboPanel.Layout.Column = 1;
            comboPanel.BackgroundColor = [0.3 0.3 0.3];
            
            comboGrid = uigridlayout(comboPanel, [1 5]);
            comboGrid.ColumnWidth = {'fit', '1x', 'fit', '1x', 'fit'};
            comboGrid.Padding = [5 5 5 5];
            
            % First rider dropdown
            uilabel(comboGrid, 'Text', 'Rider 1:', 'FontColor', [1 1 1]);
            obj.Rider1DropDown = uidropdown(comboGrid, ...
                'Items', {''}, ...
                'Value', '', ...
                'ValueChangedFcn', @(dd, event) obj.onRider1Changed());
            obj.Rider1DropDown.Layout.Column = 2;
            
            % Second rider dropdown
            uilabel(comboGrid, 'Text', 'Rider 2:', 'FontColor', [1 1 1]);
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
            
            % Create scrollable panel for table
            scrollPanel = uipanel(mainGrid);
            scrollPanel.Layout.Row = 2;
            scrollPanel.Layout.Column = 1;
            scrollPanel.BackgroundColor = [0.3 0.3 0.3];
            scrollPanel.Scrollable = 'on';
            
            % Create table directly in scrollable panel with absolute positioning
            obj.RidersTable = uitable(scrollPanel);
            obj.RidersTable.Position = [10 10 1113 600];
            obj.RidersTable.ColumnEditable = false;
            obj.RidersTable.RowName = [];
            obj.RidersTable.ColumnWidth = 'auto';
            
            % Apply center alignment style to all cells
            centerStyle = uistyle('HorizontalAlignment', 'center');
            addStyle(obj.RidersTable, centerStyle);
        end
        
        function loadData(obj)
            %LOADDATA Load data from motogp_analysis_riders.csv and display in table
            if isfile(obj.CsvPath)
                try
                    T = readtable(obj.CsvPath);
                    obj.Data = T;
                    obj.updateTable();
                    obj.updateComboBoxes();
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
        
        function onClearButtonPushed(obj)
            %ONCLEARBUTTONPUSHED Clear all highlights and restore original row colors
            % Does NOT clear the combo box selections, only removes highlights
            if isempty(obj.TableData)
                return;
            end
            
            % Get table dimensions
            numRows = height(obj.TableData);
            numCols = width(obj.TableData);
            
            % Delete all style objects first
            styleObjs = findall(obj.RidersTable, 'Type', 'uistyle');
            delete(styleObjs);
            
            % Apply white background to all cells to override any highlight colors
            % This ensures all cells return to default background
            defaultStyle = uistyle('BackgroundColor', [1 1 1], 'HorizontalAlignment', 'center');
            
            % Create cell indices for all cells
            allCells = zeros(numRows * numCols, 2);
            idx = 1;
            for r = 1:numRows
                for c = 1:numCols
                    allCells(idx, :) = [r, c];
                    idx = idx + 1;
                end
            end
            
            % Apply default style to all cells
            addStyle(obj.RidersTable, defaultStyle, 'cell', allCells);
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
    end
end

