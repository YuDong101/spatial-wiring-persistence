function digest = sha256(path)
%SHA256 Hash the exact input bytes. No file is changed.
[fid, message] = fopen(path, 'rb');
if fid < 0, error('wmrep:FileReadFailed', '%s', message); end
clean = onCleanup(@() fclose(fid));
engine = java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    bytes = fread(fid, 1024 * 1024, '*uint8');
    engine.update(typecast(bytes, 'int8'));
end
value = typecast(engine.digest(), 'uint8');
digest = string(lower(reshape(dec2hex(value, 2).', 1, [])));
end
