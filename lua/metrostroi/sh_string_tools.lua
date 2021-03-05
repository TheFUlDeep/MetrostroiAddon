Metrostroi = Metrostroi or {}


--функция превращения стринга в нижний регистр. Мб потом добавить для других языков
local BIGRUS = {"А","Б","В","Г","Д","Е","Ё","Ж","З","И","Й","К","Л","М","Н","О","П","Р","С","Т","У","Ф","Х","Ц","Ч","Ш","Щ","Ъ","Ы","Ь","Э","Ю","Я"}
local smallrus = {"а","б","в","г","д","е","ё","ж","з","и","й","к","л","м","н","о","п","р","с","т","у","ф","х","ц","ч","ш","щ","ъ","ы","ь","э","ю","я"}
function Metrostroi.StringLower(str)
	for i in pairs(BIGRUS) do
		str = str:gsub(BIGRUS[i],smallrus[i])
	end
	return string.lower(str)
end