Text={
    content = '';
    lines = {
        columns = {};
    };
};

local lineBreak = '\n';

function Text:new()
    local newObj = {}
    newObj.content = ''
    newObj.lines = { columns = {} }
    setmetatable(newObj, self)
    self.__index = self
    return newObj
end;

function Text:append(str)
    if str ~= nil then
        self.content = self.content..str;
    end;
end

function Text:appendLine(str)
    if str ~= nil then
        if self.content ~= '' then
            self.content = self.content..lineBreak;
        end;
        self.content = self.content..str;
    end;
end

function Text:breakLine()
    self.content = self.content..lineBreak;
end

function Text:breakLines(count)
    if count ~= nil then
        for i=1,count do
            self:breakLine()
        end
    end
end

function Text:toString()
    return self.content;
end

return Text;