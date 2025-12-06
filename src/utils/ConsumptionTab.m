classdef ConsumptionTab < handle
    % ConsumptionTab
    % Tab to track fuel consumption for different sessions:
    %   - FP1, PR, FP2, Q1, Q2, RAC
    % Each session tracks:
    %   - Fuel in
    %   - Fuel left
    %   - Fuel added
    %   - Total laps
    %   - Calculated: Fuel Consumption Kg/Lap = (Fuel in + Fuel added - Fuel left) / Total laps
    %   - Calculated: Total km session = Total laps * Track distance
    
    properties
        ParentTabGroup
        ParentFigure
        Tab
        
        MainGrid
        
        % Track distance
        TrackDistanceLabel
        TrackDistanceTextBox
        
        % Buttons
        LoadButton
        SaveButton
        
        % Session blocks (6 sessions: FP1, PR, FP2, Q1, Q2, RAC)
        SessionNames = {'FP1', 'PR', 'FP2', 'Q1', 'Q2', 'RAC'};
        SessionPanels
        SessionFuelInLabels
        SessionFuelInTextBoxes
        SessionFuelLeftLabels
        SessionFuelLeftTextBoxes
        SessionFuelAddedLabels
        SessionFuelAddedTextBoxes
        SessionTotalLapsLabels
        SessionTotalLapsTextBoxes
        SessionFuelConsumptionLabels
        SessionFuelConsumptionValues
        SessionTotalKmLabels
        SessionTotalKmValues
        SessionKmLitreLabels
        SessionKmLitreValues
        
        % Data
        CsvPath
        Data struct
    end
    
    methods
        function obj = ConsumptionTab(tabGroup, parentFigure, csvPath)
            obj.ParentTabGroup = tabGroup;
            obj.ParentFigure   = parentFigure;
            obj.CsvPath        = csvPath;
            
            % Initialize data structure
            obj.Data = struct();
            obj.Data.TrackDistance = '0';
            for i = 1:length(obj.SessionNames)
                session = obj.SessionNames{i};
                obj.Data.(session) = struct('FuelIn', '0', 'FuelLeft', '0', ...
                    'FuelAdded', '0', 'TotalLaps', '0');
            end
            
            obj.createUI();
            obj.loadData();
        end
    end
    
    methods (Access = private)
        
        function createUI(obj)
            % Create tab
            obj.Tab = uitab(obj.ParentTabGroup);
            obj.Tab.Title = 'Consumption';
            
            % Try to set tab background to dark grey
            try
                obj.Tab.BackgroundColor = [0.3 0.3 0.3]; % Dark grey
            catch
                % BackgroundColor may not be directly supported
            end
            
            % Main grid layout: header row + 2 rows of 3 session blocks
            obj.MainGrid = uigridlayout(obj.Tab, [3 3]);
            obj.MainGrid.RowHeight = {'fit', '1x', '1x'};
            obj.MainGrid.ColumnWidth = {'1x', '1x', '1x'};
            obj.MainGrid.RowSpacing = 10;
            obj.MainGrid.ColumnSpacing = 10;
            obj.MainGrid.Padding = [10 10 10 10];
            obj.MainGrid.BackgroundColor = [0.3 0.3 0.3]; % Dark grey background
            
            %% Top row: Track distance and buttons (spans all 3 columns)
            topPanel = uipanel(obj.MainGrid);
            topPanel.Layout.Row = 1;
            topPanel.Layout.Column = [1 3];
            
            topGrid = uigridlayout(topPanel, [1 5]);
            topGrid.ColumnWidth = {'fit', 'fit', '1x', 'fit', 'fit'};
            topGrid.Padding = [5 5 5 5];
            
            % Track distance
            obj.TrackDistanceLabel = uilabel(topGrid, 'Text', 'Track distance (km):');
            obj.TrackDistanceLabel.Layout.Column = 1;
            obj.TrackDistanceTextBox = uieditfield(topGrid, 'numeric', ...
                'Value', 0, ...
                'ValueChangedFcn', @(src, event) obj.onTrackDistanceChanged());
            obj.TrackDistanceTextBox.Layout.Column = 2;
            obj.TrackDistanceTextBox.Placeholder = 'Enter track distance';
            
            % Spacer
            uilabel(topGrid, 'Text', '');
            topGrid.Children(end).Layout.Column = 3;
            
            % Load button
            obj.LoadButton = uibutton(topGrid, ...
                'Text', 'Load', ...
                'ButtonPushedFcn', @(btn, event) obj.onLoadButtonPushed());
            obj.LoadButton.Layout.Column = 4;
            
            % Save button
            obj.SaveButton = uibutton(topGrid, ...
                'Text', 'Save', ...
                'ButtonPushedFcn', @(btn, event) obj.onSaveButtonPushed());
            obj.SaveButton.Layout.Column = 5;
            
            %% Create 6 session blocks (2 rows x 3 columns)
            obj.SessionPanels = cell(1, 6);
            obj.SessionFuelInLabels = cell(1, 6);
            obj.SessionFuelInTextBoxes = cell(1, 6);
            obj.SessionFuelLeftLabels = cell(1, 6);
            obj.SessionFuelLeftTextBoxes = cell(1, 6);
            obj.SessionFuelAddedLabels = cell(1, 6);
            obj.SessionFuelAddedTextBoxes = cell(1, 6);
            obj.SessionTotalLapsLabels = cell(1, 6);
            obj.SessionTotalLapsTextBoxes = cell(1, 6);
            obj.SessionFuelConsumptionLabels = cell(1, 6);
            obj.SessionFuelConsumptionValues = cell(1, 6);
            obj.SessionTotalKmLabels = cell(1, 6);
            obj.SessionTotalKmValues = cell(1, 6);
            obj.SessionKmLitreLabels = cell(1, 6);
            obj.SessionKmLitreValues = cell(1, 6);
            
            for i = 1:6
                sessionName = obj.SessionNames{i};
                
                % Determine row and column position
                if i <= 3
                    row = 2;
                    col = i;
                else
                    row = 3;
                    col = i - 3;
                end
                
                % Create panel for this session
                panel = uipanel(obj.MainGrid);
                panel.Title = sessionName;
                panel.Layout.Row = row;
                panel.Layout.Column = col;
                obj.SessionPanels{i} = panel;
                
                % Create grid inside panel (7 rows: 4 input pairs + 3 calculated values)
                sessionGrid = uigridlayout(panel, [7 2]);
                sessionGrid.ColumnWidth = {'fit', '1x'};
                sessionGrid.RowHeight = repmat({'fit'}, 1, 7);
                sessionGrid.Padding = [10 10 10 10];
                sessionGrid.RowSpacing = 5;
                sessionGrid.ColumnSpacing = 5;
                
                % Fuel in
                obj.SessionFuelInLabels{i} = uilabel(sessionGrid, 'Text', 'Fuel in:');
                obj.SessionFuelInLabels{i}.Layout.Row = 1;
                obj.SessionFuelInLabels{i}.Layout.Column = 1;
                obj.SessionFuelInTextBoxes{i} = uieditfield(sessionGrid, 'numeric', ...
                    'Value', 0, ...
                    'ValueChangedFcn', @(src, event) obj.onSessionValueChanged(i, 'FuelIn'));
                obj.SessionFuelInTextBoxes{i}.Layout.Row = 1;
                obj.SessionFuelInTextBoxes{i}.Layout.Column = 2;
                obj.SessionFuelInTextBoxes{i}.Placeholder = '0';
                
                % Fuel left
                obj.SessionFuelLeftLabels{i} = uilabel(sessionGrid, 'Text', 'Fuel left:');
                obj.SessionFuelLeftLabels{i}.Layout.Row = 2;
                obj.SessionFuelLeftLabels{i}.Layout.Column = 1;
                obj.SessionFuelLeftTextBoxes{i} = uieditfield(sessionGrid, 'numeric', ...
                    'Value', 0, ...
                    'ValueChangedFcn', @(src, event) obj.onSessionValueChanged(i, 'FuelLeft'));
                obj.SessionFuelLeftTextBoxes{i}.Layout.Row = 2;
                obj.SessionFuelLeftTextBoxes{i}.Layout.Column = 2;
                obj.SessionFuelLeftTextBoxes{i}.Placeholder = '0';
                
                % Fuel added
                obj.SessionFuelAddedLabels{i} = uilabel(sessionGrid, 'Text', 'Fuel added:');
                obj.SessionFuelAddedLabels{i}.Layout.Row = 3;
                obj.SessionFuelAddedLabels{i}.Layout.Column = 1;
                obj.SessionFuelAddedTextBoxes{i} = uieditfield(sessionGrid, 'numeric', ...
                    'Value', 0, ...
                    'ValueChangedFcn', @(src, event) obj.onSessionValueChanged(i, 'FuelAdded'));
                obj.SessionFuelAddedTextBoxes{i}.Layout.Row = 3;
                obj.SessionFuelAddedTextBoxes{i}.Layout.Column = 2;
                obj.SessionFuelAddedTextBoxes{i}.Placeholder = '0';
                
                % Total laps
                obj.SessionTotalLapsLabels{i} = uilabel(sessionGrid, 'Text', 'Total laps:');
                obj.SessionTotalLapsLabels{i}.Layout.Row = 4;
                obj.SessionTotalLapsLabels{i}.Layout.Column = 1;
                obj.SessionTotalLapsTextBoxes{i} = uieditfield(sessionGrid, 'numeric', ...
                    'Value', 0, ...
                    'ValueChangedFcn', @(src, event) obj.onSessionValueChanged(i, 'TotalLaps'));
                obj.SessionTotalLapsTextBoxes{i}.Layout.Row = 4;
                obj.SessionTotalLapsTextBoxes{i}.Layout.Column = 2;
                obj.SessionTotalLapsTextBoxes{i}.Placeholder = '0';
                
                % Fuel Consumption (calculated)
                obj.SessionFuelConsumptionLabels{i} = uilabel(sessionGrid, ...
                    'Text', 'Fuel Consumption Kg/Lap:');
                obj.SessionFuelConsumptionLabels{i}.Layout.Row = 5;
                obj.SessionFuelConsumptionLabels{i}.Layout.Column = 1;
                obj.SessionFuelConsumptionValues{i} = uilabel(sessionGrid, 'Text', '0.0');
                obj.SessionFuelConsumptionValues{i}.Layout.Row = 5;
                obj.SessionFuelConsumptionValues{i}.Layout.Column = 2;
                obj.SessionFuelConsumptionValues{i}.HorizontalAlignment = 'center';
                
                % Total km session (calculated)
                obj.SessionTotalKmLabels{i} = uilabel(sessionGrid, ...
                    'Text', 'Total km session:');
                obj.SessionTotalKmLabels{i}.Layout.Row = 6;
                obj.SessionTotalKmLabels{i}.Layout.Column = 1;
                obj.SessionTotalKmValues{i} = uilabel(sessionGrid, 'Text', '0.0');
                obj.SessionTotalKmValues{i}.Layout.Row = 6;
                obj.SessionTotalKmValues{i}.Layout.Column = 2;
                obj.SessionTotalKmValues{i}.HorizontalAlignment = 'center';
                
                % KM/Litre (calculated)
                obj.SessionKmLitreLabels{i} = uilabel(sessionGrid, ...
                    'Text', 'KM/Litre:');
                obj.SessionKmLitreLabels{i}.Layout.Row = 7;
                obj.SessionKmLitreLabels{i}.Layout.Column = 1;
                obj.SessionKmLitreValues{i} = uilabel(sessionGrid, 'Text', '0.0');
                obj.SessionKmLitreValues{i}.Layout.Row = 7;
                obj.SessionKmLitreValues{i}.Layout.Column = 2;
                obj.SessionKmLitreValues{i}.HorizontalAlignment = 'center';
            end
        end
        
        function onTrackDistanceChanged(obj)
            % Update calculations when track distance changes
            obj.Data.TrackDistance = num2str(obj.TrackDistanceTextBox.Value);
            obj.updateAllCalculations();
        end
        
        function onSessionValueChanged(obj, sessionIdx, fieldName)
            % Update data and recalculate when session values change
            sessionName = obj.SessionNames{sessionIdx};
            textbox = obj.getSessionTextBox(sessionIdx, fieldName);
            value = textbox.Value;
            
            % Store as string
            obj.Data.(sessionName).(fieldName) = num2str(value);
            
            % Update calculations
            obj.updateSessionCalculations(sessionIdx);
        end
        
        function textbox = getSessionTextBox(obj, sessionIdx, fieldName)
            switch fieldName
                case 'FuelIn'
                    textbox = obj.SessionFuelInTextBoxes{sessionIdx};
                case 'FuelLeft'
                    textbox = obj.SessionFuelLeftTextBoxes{sessionIdx};
                case 'FuelAdded'
                    textbox = obj.SessionFuelAddedTextBoxes{sessionIdx};
                case 'TotalLaps'
                    textbox = obj.SessionTotalLapsTextBoxes{sessionIdx};
            end
        end
        
        function updateSessionCalculations(obj, sessionIdx)
            % Update calculations for a specific session
            % Get numeric values directly from textboxes
            fuelIn = obj.SessionFuelInTextBoxes{sessionIdx}.Value;
            fuelLeft = obj.SessionFuelLeftTextBoxes{sessionIdx}.Value;
            fuelAdded = obj.SessionFuelAddedTextBoxes{sessionIdx}.Value;
            totalLaps = obj.SessionTotalLapsTextBoxes{sessionIdx}.Value;
            trackDistance = obj.TrackDistanceTextBox.Value;
            
            % Handle NaN values
            if isnan(fuelIn), fuelIn = 0; end
            if isnan(fuelLeft), fuelLeft = 0; end
            if isnan(fuelAdded), fuelAdded = 0; end
            if isnan(totalLaps), totalLaps = 0; end
            if isnan(trackDistance), trackDistance = 0; end
            
            % Calculate Fuel Consumption Kg/Lap = (Fuel in + Fuel added - Fuel left) / Total laps
            if totalLaps > 0
                fuelConsumption = (fuelIn + fuelAdded - fuelLeft) / totalLaps;
                obj.SessionFuelConsumptionValues{sessionIdx}.Text = sprintf('%.3f', fuelConsumption);
            else
                obj.SessionFuelConsumptionValues{sessionIdx}.Text = '0.0';
            end
            
            % Calculate Total km session = Total laps * Track distance
            if totalLaps > 0 && trackDistance > 0
                totalKm = totalLaps * trackDistance;
                obj.SessionTotalKmValues{sessionIdx}.Text = sprintf('%.2f', totalKm);
            else
                obj.SessionTotalKmValues{sessionIdx}.Text = '0.0';
            end
            
            % Calculate KM/Litre = (track distance * 0.77) / (Fuel Consumption Kg/Lap)
            if totalLaps > 0 && trackDistance > 0
                fuelConsumption = (fuelIn + fuelAdded - fuelLeft) / totalLaps;
                if fuelConsumption > 0
                    kmLitre = (trackDistance * 0.77) / fuelConsumption;
                    obj.SessionKmLitreValues{sessionIdx}.Text = sprintf('%.2f', kmLitre);
                else
                    obj.SessionKmLitreValues{sessionIdx}.Text = '0.0';
                end
            else
                obj.SessionKmLitreValues{sessionIdx}.Text = '0.0';
            end
        end
        
        function updateAllCalculations(obj)
            % Update calculations for all sessions
            for i = 1:6
                obj.updateSessionCalculations(i);
            end
        end
        
        function val = parseNumeric(obj, str)
            % Parse string to numeric, return NaN if invalid
            if isempty(str) || (ischar(str) && isempty(strtrim(str))) || ...
               (iscell(str) && isempty(str))
                val = NaN;
                return;
            end
            
            if iscell(str)
                str = strjoin(str, '');
            end
            
            if ischar(str) || isstring(str)
                val = str2double(str);
            else
                val = double(str);
            end
            
            if isnan(val)
                val = NaN;
            end
        end
        
        function loadData(obj)
            %LOADDATA Load data from consumption.csv
            if isfile(obj.CsvPath)
                try
                    T = readtable(obj.CsvPath);
                    
                    % Load track distance
                    if ismember('TrackDistance', T.Properties.VariableNames)
                        trackDist = T.TrackDistance(1);
                        if ~ismissing(trackDist)
                            obj.Data.TrackDistance = num2str(trackDist);
                            obj.TrackDistanceTextBox.Value = trackDist;
                        end
                    end
                    
                    % Load session data
                    for i = 1:length(obj.SessionNames)
                        sessionName = obj.SessionNames{i};
                        
                        % Load FuelIn
                        colName = [sessionName '_FuelIn'];
                        if ismember(colName, T.Properties.VariableNames)
                            val = T.(colName)(1);
                            if ~ismissing(val)
                                obj.Data.(sessionName).FuelIn = num2str(val);
                                obj.SessionFuelInTextBoxes{i}.Value = val;
                            end
                        end
                        
                        % Load FuelLeft
                        colName = [sessionName '_FuelLeft'];
                        if ismember(colName, T.Properties.VariableNames)
                            val = T.(colName)(1);
                            if ~ismissing(val)
                                obj.Data.(sessionName).FuelLeft = num2str(val);
                                obj.SessionFuelLeftTextBoxes{i}.Value = val;
                            end
                        end
                        
                        % Load FuelAdded
                        colName = [sessionName '_FuelAdded'];
                        if ismember(colName, T.Properties.VariableNames)
                            val = T.(colName)(1);
                            if ~ismissing(val)
                                obj.Data.(sessionName).FuelAdded = num2str(val);
                                obj.SessionFuelAddedTextBoxes{i}.Value = val;
                            end
                        end
                        
                        % Load TotalLaps
                        colName = [sessionName '_TotalLaps'];
                        if ismember(colName, T.Properties.VariableNames)
                            val = T.(colName)(1);
                            if ~ismissing(val)
                                obj.Data.(sessionName).TotalLaps = num2str(val);
                                obj.SessionTotalLapsTextBoxes{i}.Value = val;
                            end
                        end
                    end
                    
                    % Update all calculations
                    obj.updateAllCalculations();
                    
                catch ME
                    warning('ConsumptionTab:ReadError', ...
                        'Error reading %s: %s', obj.CsvPath, ME.message);
                end
            end
        end
        
        function onLoadButtonPushed(obj)
            %ONLOADBUTTONPUSHED Load data from consumption.csv automatically
            obj.loadData();
        end
        
        function onSaveButtonPushed(obj)
            %ONSAVEBUTTONPUSHED Save current data to consumption.csv automatically
            try
                % Build table structure
                dataRow = struct();
                
                % Add track distance
                dataRow.TrackDistance = obj.TrackDistanceTextBox.Value;
                if isnan(dataRow.TrackDistance)
                    dataRow.TrackDistance = 0;
                end
                
                % Add session data
                for i = 1:length(obj.SessionNames)
                    sessionName = obj.SessionNames{i};
                    
                    dataRow.([sessionName '_FuelIn']) = obj.SessionFuelInTextBoxes{i}.Value;
                    if isnan(dataRow.([sessionName '_FuelIn']))
                        dataRow.([sessionName '_FuelIn']) = 0;
                    end
                    
                    dataRow.([sessionName '_FuelLeft']) = obj.SessionFuelLeftTextBoxes{i}.Value;
                    if isnan(dataRow.([sessionName '_FuelLeft']))
                        dataRow.([sessionName '_FuelLeft']) = 0;
                    end
                    
                    dataRow.([sessionName '_FuelAdded']) = obj.SessionFuelAddedTextBoxes{i}.Value;
                    if isnan(dataRow.([sessionName '_FuelAdded']))
                        dataRow.([sessionName '_FuelAdded']) = 0;
                    end
                    
                    dataRow.([sessionName '_TotalLaps']) = obj.SessionTotalLapsTextBoxes{i}.Value;
                    if isnan(dataRow.([sessionName '_TotalLaps']))
                        dataRow.([sessionName '_TotalLaps']) = 0;
                    end
                end
                
                % Convert struct to table
                T = struct2table(dataRow);
                
                % Write to CSV
                writetable(T, obj.CsvPath);
                
            catch ME
                uialert(obj.ParentFigure, ...
                    sprintf('Error saving CSV file:\n%s', ME.message), ...
                    'Save Error', 'Icon', 'error');
            end
        end
    end
end

