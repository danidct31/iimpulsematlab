classdef ChecklistTab < handle
    %CHECKLISTTAB Manages the Checklist tab UI and interactions
    
    properties (Access = public)
        Tab                matlab.ui.container.Tab
        Table1             matlab.ui.control.Table
        Table2             matlab.ui.control.Table
        Table3             matlab.ui.control.Table
        Table4             matlab.ui.control.Table
        SaveButton         matlab.ui.control.Button
        LoadButton         matlab.ui.control.Button
        GeneralLabel       matlab.ui.control.Label
        PerRiderLabel      matlab.ui.control.Label
        PreRaceLabel       matlab.ui.control.Label
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
            obj.enforceSizes(); % Force correct sizes after everything is created
        end
        
        function initializeTables(obj)
            %INITIALIZETABLES Initialize all four tables with empty data
            % Table1 starts with 8 rows (5 + 3 more)
            % Table2 and Table3 start with 12 rows each
            obj.Table1.Data = obj.Manager.createEmptyTable(8);
            obj.Table2.Data = obj.Manager.createEmptyTable(12);
            obj.Table3.Data = obj.Manager.createEmptyTable(12);
            obj.Table4.Data = obj.Manager.createEmptyTable(5); % Table4 should have 5 rows
            
            obj.refreshAllRowColors();
            
            % Try to load from CSV if it exists
            obj.loadFromCSV();
        end
        
        function refreshAllRowColors(obj)
            %REFRESHALLROWCOLORS Update row colors for all four tables
            obj.refreshRowColors(obj.Table1);
            obj.refreshRowColors(obj.Table2);
            obj.refreshRowColors(obj.Table3);
            obj.refreshRowColors(obj.Table4);
        end
        
        function refreshRowColors(obj, tbl)
            %REFRESHRowCOLORS Update row colors for a single table
            D = tbl.Data;
            nRows = size(D,1);
            C = ones(nRows,3);
            if ~isempty(D) && any(D.Checked)
                C(D.Checked,:) = repmat([0.7 0.9 1], sum(D.Checked), 1);
            end
            tbl.BackgroundColor = C;
        end
        
        function onCellEdit(obj, ~, event)
            %ONCELLEDIT Callback for when a cell is edited
            tbl = event.Source;
            if ~isempty(event.Indices) && event.Indices(2) == 1
                % Repaint just this row; keep sizes consistent
                nRows = size(tbl.Data,1);
                C = tbl.BackgroundColor;
                if isempty(C) || size(C,1) ~= nRows
                    C = ones(nRows,3);
                end
                r = event.Indices(1);
                if tbl.Data.Checked(r)
                    C(r,:) = [0.7 0.9 1];
                else
                    C(r,:) = [1 1 1];
                end
                tbl.BackgroundColor = C;
            end
        end
        
        function onSaveButtonPushed(obj, ~, ~)
            %ONSAVEBUTTONPUSHED Save all checklists to CSV
            obj.Manager.saveChecklists(obj.Table1, obj.Table2, obj.Table3, obj.Table4, obj.ParentFigure);
        end
        
        function onLoadButtonPushed(obj, ~, ~)
            %ONLOADBUTTONPUSHED Load checklists from CSV
            obj.loadFromCSV();
        end
        
        function loadFromCSV(obj)
            %LOADFROMCSV Load checklists from CSV file
            [T1, T2, T3, T4] = obj.Manager.loadChecklists(obj.ParentFigure);
            obj.Table1.Data = T1;
            obj.Table2.Data = T2;
            obj.Table3.Data = T3;
            % Limit Table4 to 5 rows maximum
            if height(T4) > 5
                obj.Table4.Data = T4(1:5, :);
            else
                obj.Table4.Data = T4;
            end
            obj.refreshAllRowColors();
            obj.enforceSizes(); % Re-enforce sizes after loading
        end
        
        function enforceSizes(obj)
            %ENFORCESIZES Force button and table sizes to correct values
            % This is called after UI creation to override any auto-sizing
            
            % Force button sizes (now on left side)
            buttonWidth = 100;
            buttonHeight = 22;
            leftMarginButtons = 7;
            buttonSpacing = 5;
            buttonY = 558;
            
            loadButtonX = leftMarginButtons;
            saveButtonX = leftMarginButtons + buttonWidth + buttonSpacing;
            
            % Force both button widths to exactly 100px
            if isvalid(obj.LoadButton)
                obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
                drawnow;
                obj.LoadButton.Position(3) = buttonWidth;
                obj.LoadButton.Position(4) = buttonHeight;
            end
            
            if isvalid(obj.SaveButton)
                obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
                drawnow;
                obj.SaveButton.Position(3) = buttonWidth;
                obj.SaveButton.Position(4) = buttonHeight;
            end
            
            % Force Table4 height to exactly 5 rows
            if isvalid(obj.Table4)
                rowHeight = 25;
                table4Height = 5 * rowHeight + 30; % 5 rows + header
                currentPos = obj.Table4.Position;
                obj.Table4.Position = [currentPos(1) currentPos(2) currentPos(3) table4Height];
                drawnow;
                obj.Table4.Position(4) = table4Height;
            end
        end
    end
    
    methods (Access = private)
        function createUI(obj, parentTabGroup)
            %CREATEUI Create all UI components for the checklist tab
            % Layout: Vertical stack, all full width (1133px)
            
            % Create ChecklistTab
            obj.Tab = uitab(parentTabGroup);
            obj.Tab.Title = 'Checklist';
            
            % App width is 1133 pixels (from TabGroup position)
            appWidth = 1133;
            leftMargin = 7;
            tableWidth = appWidth - 2*leftMargin;
            
            % Create LoadButton (top left)
            buttonWidth = 100;
            buttonSpacing = 5;
            buttonHeight = 22;
            buttonY = 558;
            leftMarginButtons = 7;
            
            % Calculate positions from left edge
            loadButtonX = leftMarginButtons;
            saveButtonX = leftMarginButtons + buttonWidth + buttonSpacing;
            
            % Create LoadButton with explicit fixed size
            obj.LoadButton = uibutton(obj.Tab, 'push');
            obj.LoadButton.Text = 'Load';
            obj.LoadButton.ButtonPushedFcn = @(src, event) obj.onLoadButtonPushed(src, event);
            % Explicitly set size - use Position vector [x y width height]
            obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
            
            % Create SaveButton with same explicit fixed size
            obj.SaveButton = uibutton(obj.Tab, 'push');
            obj.SaveButton.Text = 'Save';
            obj.SaveButton.ButtonPushedFcn = @(src, event) obj.onSaveButtonPushed(src, event);
            % Explicitly set size - use Position vector [x y width height]
            obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
            
            % Force both buttons to exact same size - set multiple times to override auto-sizing
            drawnow; % Force UI update
            obj.LoadButton.Position(3) = buttonWidth;  % Force width
            obj.LoadButton.Position(4) = buttonHeight; % Force height
            obj.SaveButton.Position(3) = buttonWidth;  % Force width
            obj.SaveButton.Position(4) = buttonHeight; % Force height
            
            % Set full position again as final override
            obj.LoadButton.Position = [loadButtonX buttonY buttonWidth buttonHeight];
            obj.SaveButton.Position = [saveButtonX buttonY buttonWidth buttonHeight];
            
            % Vertical layout starting from top (y=580) going down
            currentY = 580;
            labelHeight = 22;
            tableSpacing = 5;
            
            % 1. Pre-Race Label (centered above Table1)
            obj.PreRaceLabel = uilabel(obj.Tab);
            obj.PreRaceLabel.FontWeight = 'bold';
            obj.PreRaceLabel.HorizontalAlignment = 'center';
            labelWidth = 100; % Width of label text area
            labelX = leftMargin + (tableWidth - labelWidth) / 2; % Center the label over the table
            obj.PreRaceLabel.Position = [labelX currentY - labelHeight labelWidth labelHeight];
            obj.PreRaceLabel.Text = 'Pre-Race';
            currentY = currentY - labelHeight - tableSpacing;
            
            % 2. Table1 (Pre-Race) - Full width, 2 rows visible height, but 5 rows of data
            rowHeight = 25; % Approximate height per row
            table1Height = 2 * rowHeight + 30 - (rowHeight/5); % 2 rows visible + header - 1/5 row
            obj.Table1 = uitable(obj.Tab);
            obj.Table1.ColumnName = {'Check'; 'Text'};
            obj.Table1.ColumnWidth = {50, '1x'};
            obj.Table1.RowName = {};
            obj.Table1.ColumnEditable = true;
            obj.Table1.Position = [leftMargin currentY - table1Height tableWidth table1Height];
            obj.Table1.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            currentY = currentY - table1Height - tableSpacing;
            
            % 3. Per Rider and General Labels (centered above their respective tables)
            spacing = 10;
            halfWidth = (tableWidth - spacing) / 2;
            
            % Per Rider label - centered above Table2 (left half)
            obj.PerRiderLabel = uilabel(obj.Tab);
            obj.PerRiderLabel.FontWeight = 'bold';
            obj.PerRiderLabel.HorizontalAlignment = 'center';
            labelX2 = leftMargin + (halfWidth - labelWidth) / 2; % Center over left half
            obj.PerRiderLabel.Position = [labelX2 currentY - labelHeight labelWidth labelHeight];
            obj.PerRiderLabel.Text = 'JK66';
            
            % General label - centered above Table3 (right half)
            obj.GeneralLabel = uilabel(obj.Tab);
            obj.GeneralLabel.FontWeight = 'bold';
            obj.GeneralLabel.HorizontalAlignment = 'center';
            labelX3 = leftMargin + halfWidth + spacing + (halfWidth - labelWidth) / 2; % Center over right half
            obj.GeneralLabel.Position = [labelX3 currentY - labelHeight labelWidth labelHeight];
            obj.GeneralLabel.Text = 'EO08';
            currentY = currentY - labelHeight - tableSpacing;
            
            % 4. Table2 and Table3 side by side (12 rows visible, reduced from 15)
            rowHeight = 25; % Approximate height per row
            table23Height = 12 * rowHeight + 30 - (rowHeight/5); % 12 rows visible + header - 1/5 row
            table23Width = halfWidth;
            
            % Table2 (Per Rider) - Left side
            obj.Table2 = uitable(obj.Tab);
            obj.Table2.ColumnName = {'Check'; 'Text'};
            obj.Table2.ColumnWidth = {50, '1x'};
            obj.Table2.RowName = {};
            obj.Table2.ColumnEditable = true;
            obj.Table2.Position = [leftMargin currentY - table23Height table23Width table23Height];
            obj.Table2.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            
            % Table3 (General) - Right side
            obj.Table3 = uitable(obj.Tab);
            obj.Table3.ColumnName = {'Check'; 'Text'};
            obj.Table3.ColumnWidth = {50, '1x'};
            obj.Table3.RowName = {};
            obj.Table3.ColumnEditable = true;
            obj.Table3.Position = [leftMargin + halfWidth + spacing currentY - table23Height table23Width table23Height];
            obj.Table3.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
            currentY = currentY - table23Height - tableSpacing;
            
            % 7. Table4 - Full width (no label), 5 rows height
            table4Height = 5 * rowHeight + 30; % 5 rows + header
            obj.Table4 = uitable(obj.Tab);
            obj.Table4.ColumnName = {'Check'; 'Text'};
            obj.Table4.ColumnWidth = {50, '1x'};
            obj.Table4.RowName = {};
            obj.Table4.ColumnEditable = true;
            obj.Table4.Position = [leftMargin currentY - table4Height tableWidth table4Height];
            obj.Table4.CellEditCallback = @(src, event) obj.onCellEdit(src, event);
        end
    end
end

