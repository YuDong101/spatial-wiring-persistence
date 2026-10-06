function [points, source] = load_coordinates(path)
%LOAD_COORDINATES Read user-supplied CSV x,y,z or MAT points/whole_v783.points.
if ~(ischar(path) && isrow(path) || isstring(path) && isscalar(path)) || ...
        ismissing(string(path)) || ~isfile(path)
    error('wmrep:CoordinateFileMissing', ...
        'Supply a coordinate file obtained from the source in README.md.');
end
[~, name, ext] = fileparts(path);
switch lower(string(ext))
    case '.csv'
        data = readtable(path, 'VariableNamingRule', 'preserve');
        if ~all(ismember({'x','y','z'}, data.Properties.VariableNames))
            error('wmrep:InvalidCoordinates', 'CSV columns must include x, y, z.');
        end
        points = data{:, {'x','y','z'}};
    case '.mat'
        names = string({whos('-file', path).name});
        if ismember('points', names)
            data = load(path, 'points'); points = data.points;
        elseif ismember('whole_v783', names)
            data = load(path, 'whole_v783');
            if ~isstruct(data.whole_v783) || ~isscalar(data.whole_v783) || ...
                    ~isfield(data.whole_v783, 'points')
                error('wmrep:InvalidCoordinates', 'Expected whole_v783.points.');
            end
            points = data.whole_v783.points;
        else
            error('wmrep:InvalidCoordinates', 'MAT must contain points or whole_v783.points.');
        end
    otherwise
        error('wmrep:InvalidCoordinates', 'Use a CSV or MAT coordinate file.');
end
if ~isnumeric(points) || ~isreal(points) || ~ismatrix(points) || ...
        isempty(points) || size(points, 2) ~= 3 || any(~isfinite(points(:)))
    error('wmrep:InvalidCoordinates', 'Coordinates must be a finite real N-by-3 numeric matrix.');
end
points = double(points);
info = dir(path);
source = struct('name', string(name) + string(ext), 'bytes', info.bytes, ...
    'sha256', wmrep.sha256(path), 'rows', size(points, 1));
end
