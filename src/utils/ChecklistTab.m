classdef ChecklistTab < handle
    %CHECKLISTTAB Manages the Checklist tab UI and interactions
    
    properties (Access = public)
        Tab                matlab.ui.container.Tab
        Table1             matlab.ui.control.Table
        Table5             matlab.ui.control.Table
        Table2             matlab.ui.control.Table
        Table3             matlab.ui.control.Table
        Table4             matlab.ui.control.Table
        SaveButton         matlab.ui.control.Button
        LoadButton         matlab.ui.control.Button
    end
    
    properties (Access = private)
        Manager            ChecklistManager
        ParentFigure       matlab.ui.Figure
        ItemsPerList       double
    end
    
    methods
        function obj = ChecklistTab(parentTabGroup, parentFigure, csvPath, itemsPerList)
            %CHECKLISTTAB Constructor
            %   parentTabGroup: TabGroup to add the checklist tab to
            %   parentFigure: Main UIFigure for dialogs
            %   csvPath: Path to CSV file for saving/loading
            %   itemsPerList: Number of items per checklist (default: 40)
            
            if nargin < 4
                itemsPerList = 40;
            end
            
            obj.ParentFigure = parentFigure;
            obj.ItemsPerList = itemsPerList;
            obj.Manager = ChecklistManager(csvPath, itemsPerList);
            
            obj.createUI(parentTabGroup);
            obj.initializeTables();
        end
        
        function initializeTables(obj)
            %INITIALIZETABLES Initialize all five tables with empty data
            % Table1 and Table5 start with 13 rows each
            % Table2 and Table3 start with 21 rows each
            T1 = obj.Manager.createEmptyTable(13);
            T1.Properties.VariableNames{'Text'} = 'Pre-Race';
            T1 = obj.reorderTableColumns(T1);
            obj.Table1.Data = T1;
            
            T5 = obj.Manager.createEmptyTable(13);
            T5.Properties.VariableNames{'Text'} = 'Text';
            T5 = obj.reorderTableColumns(T5);
            obj.Table5.Data = T5;
            
            T2 = obj.Manager.createEmptyTable(21);
            T2.Properties.VariableNames{'Text'} = 'JK66';
            T2 = obj.reorderTableColumns(T2);
            obj.Table2.Data = T2;
            
            T3 = obj.Manager.createEmptyTable(21);
            T3.Properties.VariableNames{'Text'} = 'EO08';
            T3 = obj.reorderTableColumns(T3);
            obj.Table3.Data = T3;
            
            T4 = obj.Manager.createEmptyTable(5);
            T4 = obj.reorderTableColumns(T4);
            obj.Table4.Data = T4;
            
            obj.refreshAllRowColors();
            
            % Try to load from CSV if it exists
            obj.loadFromCSV();
        end
        
        function refreshAllRowColors(obj)
            %REFRESHALLROWCOLORS Update row colors for all five tables
            obj.refreshRowColors(obj.Table1);
            obj.refreshRowColors(obj.Table5);
            obj.refreshRowColors(obj.Table2);
            obj.refreshRowColors(obj.Table3);
            obj.refreshRowColors(obj.Table4);
        end
        
        function refreshRowColors(obj, tbl)
            %REFRESHROWCOLORS Update row colors for a single table
            %   Logic: Check column checked -> blue, Orange column checked -> orange,
            %   both unchecked -> white
            D = tbl.Data;
            nRows = size(D,1);
            C = ones(nRows,3);  % Default white
            
            % Ensure Orange column exists
            if ~ismember('Orange', D.Properties.VariableNames)
                D.Orange = false(nRows, 1);
                tbl.Data = D;
            end
            
            % Apply colors based on checkbox states
            for r = 1:nRows
                if D.Checked(r)
                    % Check column checked: blue background
                    C(r,:) = [0.7 0.9 1];  % Light blue
                elseif D.Orange(r)
                    % Orange column checked: orange background
                    C(r,:) = [1 0.5 0];  % Orange
                else
                    % Both unchecked: white background
                    C(r,:) = [1 1 1];  % White
                end
            end
            tbl.BackgroundColor = C;
        end
        
        function onCellEdit(obj, ~, event)
            %ONCELLEDIT Callback for when a cell is edited
            %   Handles both Check column (column 1) and Orange column (column 2)
            %   Ensures only one checkbox per row can be checked at a time
            tbl = event.Source;
            if ~isempty(event.Indices) && (event.Indices(2) == 1 || event.Indices(2) == 2)
                row = event.Indices(1);
                col = event.Indices(2);
                data = tbl.Data;
                
                % Ensure Orange column exists
                if ~ismember('Orange', data.Properties.VariableNames)
                    data.Orange = false(height(data), 1);
                end
                
                % Get the new value that was just set
                newValue = data{row, col};
                
                % If a checkbox was checked, uncheck the other one
                if newValue && col == 1
                    % Check column was checked - uncheck Orange column
                    data.Orange(row) = false;
                elseif newValue && col == 2
                    % Orange column was checked - uncheck Check column
                    data.Checked(row) = false;
                end
                
                % Update the table data
                tbl.Data = data;
                
                % Update row colors
                obj.refreshRowColors(tbl);
            end
        end
        
        function onCellSelection(obj, src, event)
            %ONCELLSELECTION Callback for when cells are selected
            %   Prevents cell selection for checkbox columns (columns 1 and 2)
            %   This makes it appear as if the cells can't be clicked, while
            %   checkboxes remain functional
            if ~isempty(event.Indices)
                col = event.Indices(1, 2); % Get column index
                % If checkbox column (1 or 2) is selected, clear the selection
                if col == 1 || col == 2
                    % Force a redraw and then clear selection
                    drawnow;
                    try
                        src.Selection = [];
                    catch
                        % If Selection property is read-only, try alternative approach
                        % This might not work in all MATLAB versions
                    end
                end
            end
        end
        
        function onSaveButtonPushed(obj, ~, ~)
            %ONSAVEBUTTONPUSHED Save all checklists to CSV
            obj.Manager.saveChecklists(obj.Table1, obj.Table5, obj.Table2, obj.Table3, obj.Table4, obj.ParentFigure);
        end
        
        function onLoadButtonPushed(obj, ~, ~)
            %ONLOADBUTTONPUSHED Load checklists from CSV
            obj.loadFromCSV();
        end
        
        function loadFromCSV(obj)
            %LOADFROMCSV Load checklists from CSV file
            [T1, T5, T2, T3, T4] = obj.Manager.loadChecklists(obj.ParentFigure);
            
            % Rename 'Text' column to the display names
            if ismember('Text', T1.Properties.VariableNames)
                T1.Properties.VariableNames{'Text'} = 'Pre-Race';
            end
            
            % Ensure Table1 has exactly 13 rows - pad or truncate as needed
            if height(T1) < 13
                % Pad with empty rows
                needed = 13 - height(T1);
                emptyRows = obj.Manager.createEmptyTable(needed, height(T1)+1);
                if ismember('Text', emptyRows.Properties.VariableNames)
                    emptyRows.Properties.VariableNames{'Text'} = 'Pre-Race';
                end
                T1 = [T1; emptyRows];
            elseif height(T1) > 13
                % Truncate to 13 rows
                T1 = T1(1:13, :);
            end
            
            % Reorder columns to match display: Checked, Orange, Text
            T1 = obj.reorderTableColumns(T1);
            obj.Table1.Data = T1;
            
            % Ensure Table5 has exactly 13 rows - pad or truncate as needed
            if height(T5) < 13
                needed = 13 - height(T5);
                emptyRows = obj.Manager.createEmptyTable(needed, height(T5)+1);
                T5 = [T5; emptyRows];
            elseif height(T5) > 13
                T5 = T5(1:13, :);
            end
            % Reorder columns to match display: Checked, Orange, Text
            T5 = obj.reorderTableColumns(T5);
            obj.Table5.Data = T5;
            
            if ismember('Text', T2.Properties.VariableNames)
                T2.Properties.VariableNames{'Text'} = 'JK66';
            end
            
            % Ensure Table2 has exactly 21 rows - pad or truncate as needed
            if height(T2) < 21
                needed = 21 - height(T2);
                emptyRows = obj.Manager.createEmptyTable(needed, height(T2)+1);
                if ismember('Text', emptyRows.Properties.VariableNames)
                    emptyRows.Properties.VariableNames{'Text'} = 'JK66';
                end
                T2 = [T2; emptyRows];
            elseif height(T2) > 21
                T2 = T2(1:21, :);
            end
            % Reorder columns to match display: Checked, Orange, Text (or JK66)
            T2 = obj.reorderTableColumns(T2);
            obj.Table2.Data = T2;
            
            if ismember('Text', T3.Properties.VariableNames)
                T3.Properties.VariableNames{'Text'} = 'EO08';
            end
            
            % Ensure Table3 has exactly 21 rows - pad or truncate as needed
            if height(T3) < 21
                needed = 21 - height(T3);
                emptyRows = obj.Manager.createEmptyTable(needed, height(T3)+1);
                if ismember('Text', emptyRows.Properties.VariableNames)
                    emptyRows.Properties.VariableNames{'Text'} = 'EO08';
                end
                T3 = [T3; emptyRows];
            elseif height(T3) > 21
                T3 = T3(1:21, :);
            end
            % Reorder columns to match display: Checked, Orange, Text (or EO08)
            T3 = obj.reorderTableColumns(T3);
            obj.Table3.Data = T3;
            
            % Ensure Table4 has exactly 5 rows - pad or truncate as needed
            if height(T4) < 5
                needed = 5 - height(T4);
                emptyRows = obj.Manager.createEmptyTable(needed, height(T4)+1);
                T4 = [T4; emptyRows];
            elseif height(T4) > 5
                T4 = T4(1:5, :);
            end
            % Reorder columns to match display: Checked, Orange, Text
            T4 = obj.reorderTableColumns(T4);
            obj.Table4.Data = T4;
            
            obj.refreshAllRowColors();
            % Don't reposition anything - just load the data
        end
        
        function ensureAllTablePositions(obj)
            %ENSUREALLTABLEPOSITIONS Ensure all tables maintain their positions and sizes after load
            appWidth = 1133;
            leftMargin = 7;
            tableWidth = appWidth - 2*leftMargin;
            rowHeight = 25;
            tableSpacing = 5;
            currentY = 580;
            
            % Table1 position
            if isvalid(obj.Table1)
                table1Height = 2 * rowHeight + 30 - (rowHeight/5);
                obj.Table1.Position = [leftMargin currentY - table1Height tableWidth table1Height];
            end
            currentY = currentY - table1Height - tableSpacing;
            
            % Table2 and Table3 positions
            if isvalid(obj.Table2) && isvalid(obj.Table3)
                spacing = 10;
                halfWidth = (tableWidth - spacing) / 2;
                table23Height = 12 * rowHeight + 30 - (rowHeight/5);
                obj.Table2.Position = [leftMargin currentY - table23Height halfWidth table23Height];
                obj.Table3.Position = [leftMargin + halfWidth + spacing currentY - table23Height halfWidth table23Height];
            end
            currentY = currentY - table23Height - tableSpacing;
            
            % Table4 position - ensure full width
            if isvalid(obj.Table4)
                table4Height = 3 * rowHeight + 30;
                obj.Table4.Position = [leftMargin currentY - table4Height tableWidth table4Height];
            end
        end
        
        function ensureTable4Position(obj)
            %ENSURETABLE4POSITION Ensure Table4 is in the correct position
            if isvalid(obj.Table4)
                % Calculate correct position based on layout
                appWidth = 1133;
                leftMargin = 7;
                tableWidth = appWidth - 2*leftMargin;
                rowHeight = 25;
                table4Height = 3 * rowHeight + 30; % 3 rows visible + header
                
                % Calculate Y position: start from top and work down
                currentY = 580;
                tableSpacing = 5;
                
                % Table1
                table1Height = 2 * rowHeight + 30 - (rowHeight/5);
                currentY = currentY - table1Height - tableSpacing;
                
                % Table2/3
                table23Height = 12 * rowHeight + 30 - (rowHeight/5);
                currentY = currentY - table23Height - tableSpacing;
                
                % Table4 should be here
                obj.Table4.Position = [leftMargin currentY - table4Height tableWidth table4Height];
            end
        end
        
        function T = reorderTableColumns(obj, T)
            %REORDERTABLECOLUMNS Reorder table columns to match display: Checked, Orange, Text
            %   Reorders from [Checked, Text, Orange] to [Checked, Orange, Text]
            %   Handles cases where Text column may have different names (Pre-Race, JK66, EO08)
            
            % Find the text column name (could be Text, Pre-Race, JK66, EO08)
            allCols = T.Properties.VariableNames;
            textColName = setdiff(allCols, {'Checked', 'Orange'});
            if isempty(textColName)
                % No text column found, return as is
                return;
            end
            textColName = textColName{1};
            
            % Reorder to: Checked, Orange, Text
            T = T(:, {'Checked', 'Orange', textColName});
        end
        
        function ensureButtonsVisible(obj)
            %ENSUREBUTTONSVISIBLE Make sure buttons are visible and correctly positioned
            buttonWidth = 100;
            buttonSpacing = 5;
            buttonHeight = 22;
            buttonY = 590; % Higher Y to be above tables
            leftMarginButtons = 7;
            
            loadButtonX = leftMarginButtons;
            saveButtonX = leftMarginButtons + buttonWidth + buttonSpacing;
            
            if isvalid(obj.LoadButton)
                obj.LoadButton.Visible = 'on';
                obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
                obj.LoadButton.BackgroundColor = [0.94 0.94 0.94]; % Ensure visible on dark background
                obj.LoadButton.FontColor = [0 0 0]; % Black text
                uistack(obj.LoadButton, 'top'); % Bring to front
            end
            
            if isvalid(obj.SaveButton)
                obj.SaveButton.Visible = 'on';
                obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
                obj.SaveButton.BackgroundColor = [0.94 0.94 0.94]; % Ensure visible on dark background
                obj.SaveButton.FontColor = [0 0 0]; % Black text
                uistack(obj.SaveButton, 'top'); % Bring to front
            end
        end
    end
    
    methods (Access = private)
        function createUI(obj, parentTabGroup)
            %CREATEUI Create all UI components for the checklist tab
            % Layout: Vertical stack, all full width
            
            % Create ChecklistTab
            obj.Tab = uitab(parentTabGroup);
            obj.Tab.Title = 'Checklist';
            
            % Try to set tab background to dark grey
            try
                obj.Tab.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be directly supported
            end
            
            % App width
            appWidth   = 1133;  % or parentTabGroup.Position(3);
            leftMargin = 7;
            tableWidth = appWidth - 2*leftMargin;
            
            % --- Buttons (top left, same size) ---
            buttonWidth   = 100;
            buttonSpacing = 5;
            buttonHeight  = 22;
            buttonY       = 590; % Higher Y value to be above tables (MATLAB: y=0 at bottom, higher = top)
            leftMarginButtons = 7;
            
            loadButtonX = leftMarginButtons;
            saveButtonX = leftMarginButtons + buttonWidth + buttonSpacing;
            
            % Load button - create first so it's on bottom layer
            obj.LoadButton = uibutton(obj.Tab, 'push');
            obj.LoadButton.Text = 'Load';
            obj.LoadButton.ButtonPushedFcn = @(src, event) obj.onLoadButtonPushed(src, event);
            obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
            obj.LoadButton.Visible = 'on';
            obj.LoadButton.BackgroundColor = [0.94 0.94 0.94]; % Light grey to stand out on dark background
            obj.LoadButton.FontColor = [0 0 0]; % Black text
            
            % Save button
            obj.SaveButton = uibutton(obj.Tab, 'push');
            obj.SaveButton.Text = 'Save';
            obj.SaveButton.ButtonPushedFcn = @(src, event) obj.onSaveButtonPushed(src, event);
            obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
            obj.SaveButton.Visible = 'on';
            obj.SaveButton.BackgroundColor = [0.94 0.94 0.94]; % Light grey to stand out on dark background
            obj.SaveButton.FontColor = [0 0 0]; % Black text
            
            % Move buttons to front (bring to top of z-order)
            uistack(obj.LoadButton, 'top');
            uistack(obj.SaveButton, 'top');
            
            % --- Vertical layout starting from top (y=580) going down ---
            currentY     = 580;
            labelHeight  = 22;
            tableSpacing = 5;
            
            % 1. Table1 and Table5 side by side - 125px tall
            rowHeight    = 25;
            table1Height = 125;
            spacing      = 10;
            halfWidth    = (tableWidth - spacing) / 2;
            
            % Table1 (left)
            obj.Table1 = uitable(obj.Tab);
            obj.Table1.ColumnName = {'Check'; 'Orange'; 'Pre-Race'};
            obj.Table1.ColumnWidth = {50, 50, '1x'};  % Check and Orange columns same width, text expands
            obj.Table1.RowName = {};
            obj.Table1.ColumnEditable = true;
            obj.Table1.Position = [leftMargin currentY - table1Height halfWidth table1Height];
            obj.Table1.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            obj.Table1.CellSelectionCallback = @(src, event) obj.onCellSelection(src, event);
            
            % Table5 (right)
            obj.Table5 = uitable(obj.Tab);
            obj.Table5.ColumnName = {'Check'; 'Orange'; 'Text'};
            obj.Table5.ColumnWidth = {50, 50, '1x'};  % Check and Orange columns same width, text expands
            obj.Table5.RowName = {};
            obj.Table5.ColumnEditable = true;
            obj.Table5.Position = [leftMargin + halfWidth + spacing currentY - table1Height halfWidth table1Height];
            obj.Table5.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            obj.Table5.CellSelectionCallback = @(src, event) obj.onCellSelection(src, event);
            
            currentY = currentY - table1Height - tableSpacing;
            
            % 2. Table2 and Table3 side by side (12 visible rows)
            spacing   = 10;
            halfWidth = (tableWidth - spacing) / 2;
            table23Height = 12 * rowHeight + 30 - (rowHeight/5);
            table23Width  = halfWidth;
            
            % Table2 (left)
            obj.Table2 = uitable(obj.Tab);
            obj.Table2.ColumnName = {'Check'; 'Orange'; 'JK66'};
            obj.Table2.ColumnWidth = {50, 50, '1x'};  % Check and Orange columns same width, text expands
            obj.Table2.RowName = {};
            obj.Table2.ColumnEditable = true;
            obj.Table2.Position = [leftMargin currentY - table23Height table23Width table23Height];
            obj.Table2.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            obj.Table2.CellSelectionCallback = @(src, event) obj.onCellSelection(src, event);
            
            % Table3 (right)
            obj.Table3 = uitable(obj.Tab);
            obj.Table3.ColumnName = {'Check'; 'Orange'; 'EO08'};
            obj.Table3.ColumnWidth = {50, 50, '1x'};  % Check and Orange columns same width, text expands
            obj.Table3.RowName = {};
            obj.Table3.ColumnEditable = true;
            obj.Table3.Position = [leftMargin + halfWidth + spacing currentY - table23Height table23Width table23Height];
            obj.Table3.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            obj.Table3.CellSelectionCallback = @(src, event) obj.onCellSelection(src, event);
            currentY = currentY - table23Height - tableSpacing;
            
            % 5. Table4 - Full width, 3-row visual height (but 5 data rows)
            table4Height = 3 * rowHeight + 30; % 3 rows visible + header (but has 5 data rows)
            obj.Table4 = uitable(obj.Tab);
            obj.Table4.ColumnName = {'Check'; 'Orange'; 'Text'};
            obj.Table4.ColumnWidth = {50, 50, '1x'};  % Check and Orange columns same width, text expands
            obj.Table4.RowName = {};
            obj.Table4.ColumnEditable = true;
            obj.Table4.Position = [leftMargin currentY - table4Height tableWidth table4Height];
            obj.Table4.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            obj.Table4.CellSelectionCallback = @(src, event) obj.onCellSelection(src, event);
        end
    end
end
