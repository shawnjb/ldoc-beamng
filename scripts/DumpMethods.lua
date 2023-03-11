--- find vec3 based on it's properties (x, y & z)

local x = 0;
for _, t in pairs() do
    if pcall(function() return t.x and t.y and t.z end) then
        local str = dumps(x);
        if str:find("__add") and str:find("__sub") then
            print(str);
            x = t;
            break;
        end;
    end;
end;
