classdef ChecklistManager < handle
    %CHECKLISTMANAGER Manages checklist data persistence and operations
    
    properties (Access = private)
        CSVPath string
        ItemsPerList double
    end
    
    methods
        function obj = ChecklistManager(csvPath, itemsPerList)
            %CHECKLISTMANAGER Constructor
            %   csvPath: Path to the CSV file for saving/loading
            %   itemsPerList: Number of items per checklist (default: 40)
            
            % --- Make both arguments optional & robust ---
            if nargin < 1 || isempty(csvPath)
                % Default path if none is passed
                csvPath = "checklists.csv";
            end
            if nargin < 2 || isempty(itemsPerList)
                itemsPerList = 40;
            end
            
            obj.CSVPath     = string(csvPath);
            obj.ItemsPerList = itemsPerList;
        end
        
        function saveChecklists(obj, table1, table2, table3, table4, parentFigure)
            %SAVECHECKLISTS Save all four checklist tables to a single CSV
            %   table1, table2, table3, table4: MATLAB table objects with Checked and Text columns
            %   parentFigure: UIFigure handle for error dialogs
            
            try
                % Normalize each table and stack them: list1, list2, list3, list4
                T1 = table1.Data; T1.Checked = logical(T1.Checked);
                % Handle different column names - map to 'Text' for CSV
                if ismember('Pre-Race', T1.Properties.VariableNames)
                    T1.Properties.VariableNames{'Pre-Race'} = 'Text';
                end
                T1.Text = string(T1.Text);
                
                T2 = table2.Data; T2.Checked = logical(T2.Checked);
                if ismember('JK66', T2.Properties.VariableNames)
                    T2.Properties.VariableNames{'JK66'} = 'Text';
                end
                T2.Text = string(T2.Text);
                
                T3 = table3.Data; T3.Checked = logical(T3.Checked);
                if ismember('EO08', T3.Properties.VariableNames)
                    T3.Properties.VariableNames{'EO08'} = 'Text';
                end
                T3.Text = string(T3.Text);
                
                T4 = table4.Data; T4.Checked = logical(T4.Checked);
                if ismember('Text', T4.Properties.VariableNames)
                    T4.Text = string(T4.Text);
                elseif ismember('Check', T4.Properties.VariableNames)
                    % Handle if column name is different
                    textCol = setdiff(T4.Properties.VariableNames, {'Checked', 'Check'});
                    if ~isempty(textCol)
                        T4.Properties.VariableNames{textCol{1}} = 'Text';
                        T4.Text = string(T4.Text);
                    end
                end
            
                % Normalize all tables to their expected sizes for consistent save/load
                % Table1: 13 rows, Table2: 21 rows, Table3: 21 rows, Table4: 5 rows
                T1 = obj.normalizeLen(T1, 13);
                T2 = obj.normalizeLen(T2, 21);
                T3 = obj.normalizeLen(T3, 21);
                T4 = obj.normalizeLen(T4, 5);
            
                % Concatenate and write only the two columns
                T = [T1(:,{'Checked','Text'}); ...
                     T2(:,{'Checked','Text'}); ...
                     T3(:,{'Checked','Text'}); ...
                     T4(:,{'Checked','Text'})];
                writetable(T, obj.CSVPath);
                
                % Success message removed (silent save)
                % uialert(parentFigure, "Checklist saved to " + obj.CSVPath, 'Save', 'Icon','success');
            catch ME
                uialert(parentFigure, "Save failed: " + ME.message, 'Save', 'Icon','error');
            end
        end
        
        function [T1, T2, T3, T4] = loadChecklists(obj, parentFigure)
            %LOADCHECKLISTS Load checklist data from CSV and return four tables
            %   parentFigure: UIFigure handle for error dialogs
            %   Returns: T1, T2, T3, T4 - four table objects for the four checklists
            
            % Initialize empty tables
            T1 = obj.createEmptyTable(13);  % Table1 starts with 13 rows
            T2 = obj.createEmptyTable(21); % Table2 starts with 21 rows
            T3 = obj.createEmptyTable(21); % Table3 starts with 21 rows
            T4 = obj.createEmptyTable(5);  % Table4 should have 5 rows
            
            file = obj.CSVPath;
            if ~isfile(file)
                return; % File doesn't exist, return empty tables
            end
        
            try
                T = readtable(file, 'TextType','string');
                % Accept headers "Checked,Text" or "Check,Text"
                vars = string(T.Properties.VariableNames);
                if ismember("Check", vars) && ~ismember("Checked", vars)
                    T.Properties.VariableNames{vars=="Check"} = "Checked";
                    vars = string(T.Properties.VariableNames);
                end
                if ~all(ismember(["Checked","Text"], vars))
                    uialert(parentFigure, "CSV must have columns: Checked, Text", 'Load', 'Icon','error');
                    return;
                end
        
                % Normalize types
                T.Checked = logical(T.Checked);
                T.Text    = string(T.Text);
        
                nPer = obj.ItemsPerList;
                totalRows = height(T);
                
                % Split into 4 tables...
                if totalRows >= 3*nPer && totalRows < 4*nPer
                    idx1 = 1:min(nPer, totalRows);
                    idx2 = (nPer+1):min(2*nPer, totalRows);
                    idx3 = (2*nPer+1):min(3*nPer, totalRows);
                    idx4 = [];
                else
                    % New format: Load all rows that were saved
                    % Split based on expected row counts: T1=13, T2=21, T3=21, T4=5
                    expectedT1Rows = 13;
                    expectedT2Rows = 21;
                    expectedT3Rows = 21;
                    expectedT4Rows = 5;
                    
                    % Table1: first 13 rows (or all if less)
                    idx1 = 1:min(expectedT1Rows, totalRows);
                    start2 = length(idx1) + 1;
                    
                    % Table2: next 21 rows (or remaining if less)
                    if start2 <= totalRows
                        idx2 = start2:min(start2 + expectedT2Rows - 1, totalRows);
                        start3 = start2 + length(idx2);
                    else
                        idx2 = [];
                        start3 = start2;
                    end
                    
                    % Table3: next 21 rows (or remaining if less)
                    if start3 <= totalRows
                        idx3 = start3:min(start3 + expectedT3Rows - 1, totalRows);
                        start4 = start3 + length(idx3);
                    else
                        idx3 = [];
                        start4 = start3;
                    end
                    
                    % Table4: remaining rows (up to 5, or all remaining if less)
                    if start4 <= totalRows
                        idx4 = start4:min(start4 + expectedT4Rows - 1, totalRows);
                    else
                        idx4 = [];
                    end
                end
        
                if ~isempty(idx1)
                    T1 = T(idx1, {'Checked','Text'});
                end
                if ~isempty(idx2)
                    T2 = T(idx2, {'Checked','Text'});
                end
                if ~isempty(idx3)
                    T3 = T(idx3, {'Checked','Text'});
                end
                if ~isempty(idx4)
                    T4 = T(idx4, {'Checked','Text'});
                    % Don't pad Table4 - use exactly what was saved
                end
            catch ME
                uialert(parentFigure, "Load failed: " + ME.message, 'Load', 'Icon','error');
            end
        end
        
        function emptyTable = createEmptyTable(obj, nItems, startIndex)
            %CREATEEMPTYTABLE Create an empty checklist table with nItems rows
            %   nItems: Number of items in the table
            %   startIndex: Starting index for item numbering (default: 1)
            if nargin < 3
                startIndex = 1;
            end
            emptyTable = table(false(nItems,1), ...
                               "Item " + string(startIndex:(startIndex+nItems-1))', ...
                               'VariableNames', {'Checked','Text'});
        end
    end
    
    methods (Access = private)
        function TT = normalizeLen(obj, TT, nPer)
            %NORMALIZELEN Pad or truncate table to exactly nPer rows
            if height(TT) < nPer
                addN = nPer - height(TT);
                TT = [TT; obj.createEmptyTable(addN, height(TT)+1)];
            elseif height(TT) > nPer
                TT = TT(1:nPer, :);
            end
        end
    end
end
