unit BMP;

const//Смещения в BMP файле относительно начала. 
  TYPE_OFFSET = 0;
  SIZE_OFFSET = 2;
  PIXELS_OFFSET = 10;
  WIDTH_OFFSET = 18;
  HEIGHT_OFFSET = 22;
  BIT_COUNT_OFFSET = 28;
  SIZEIMAGE_OFFSET = 34;
//Тут более подробно о них, ну, как подробнее =)
{type BMPHeader = packed record
  0bfType : WORD;//2
  2bfSize : cardinal;//4
  6bfReserved1 : WORD;//2
  8bfReserved2 : WORD;//2
  10bfOffBits : cardinal;//4
  14biSize : cardinal;//4 
  18biWidth : cardinal//4 
  22biHeight :  cardinal;//4 
  26biPlanes : WORD;//2
  28biBitCount : WORD;//2
end;
}
//Класс, который представляет собой пиксель.  
type
Pixel = class
  public Red : byte;
  public Green : byte;
  public Blue : byte;
  constructor (r : byte; g : byte; b : byte);//Конструктор, который просто заполняет поля класса. Тупо цвета red green blue
  begin
    self.Red := r;
    self.Green := g;
    self.Blue := b;
  end;
  function getBytes : array of byte;//Возврашает массив байтов { bluecolor, greencolor, redcolor } - именно в таком порядке.
  begin
    Result := new byte[3];
    Result[0] := Blue;
    Result[1] := Green;
    Result[2] := Red;
  end;
  procedure SetRed(Red: byte);//Сеттеры для полей. Они тут и не нужны, но используются, так что лан.
  begin
    self.Red := Red;
  end;
  procedure SetGreen(Green: byte);
  begin
    self.Green := Green;
  end;
 procedure SetBlue(Blue: byte);
  begin
    self.Blue := Blue;
  end;
end;

var
  pixelsOffset: cardinal;//Смещение относительно начала файла до начала пикселей
  totalPixelsBytesCount: cardinal;//Количество байтов в файле под пиксели
  width: cardinal;//Ширина
  height: cardinal;//Высота
  sizeimage: cardinal;//Структура БМПшки хранит кол-во байтов на пиксели по смещению. В эту переменную помещено значение из структуры BMP
  additional : integer;//Сколько нужно добавить байт в строчку для удовлетворения стандартам
  Header : array of byte;//BMPheader
  bitCount : WORD;
  typeNum : WORD;

function BuildPixels(pixelsArray : array of byte) : List<List<Pixel>>;//Строим пиксель. Почти что фабрика пикселей)
var
  counter : integer;//Счетчик. Нужен для соблюдения выравнивания и верного счета строчек.
  l : List<List<Pixel>>;//Результат - двумерный список или массив, как пожелаете трактовать.
  lm : List<Pixel>;//Одна строчка. Грубо говоря у нас все пиксели - двумерный массив размером высота*ширина. Так вот это одна строчка двумерного массива
  p : Pixel;//Единичный пиксель. Просто пиксель.
  portion : array of byte;//Так называемая порция - строчка из двумерного массива(списка), содержащая дополнительные байты. Они МЕШАЮТСЯ, АААААА.
begin
  lm := new List<Pixel>();//Инициализируем строчку. Использутся шаблонные классы .NET. Дженерики иначе. Суть их в том, что внутри класса не все типы изначально определены. И только пользователь-программист их определяет в таких скобках - <>
  l := new List<List<Pixel>>();//Тоже самое, что и выше
  portion := new byte[(width*3)+additional];//Инициализируем массив порции
  for i : integer := 1 to height do//Читаем все строчки
  begin
    System.Array.Copy(pixelsArray, (i-1)*portion.Length, portion, 0, portion.Length);//Копируем строчку целиком в массив-порцию
    counter := 0;//Обнуляем счетчик
    lm := new List<Pixel>();//Инициализируем массив(список) пикселей
    while(counter < width*3) do//До тех пор, пока счетчик не достиг конца строки с ИНТЕРЕСУЮЩИМИ нас байтами(отступы-дополнения нас не интересуют, они просто занулены)
    begin
      p := new Pixel(portion[counter+2], portion[counter+1], portion[counter]);//Создаем объект класса Pixel
      lm.Add(p);//Добавляем новоиспеченный пиксель в строчку
      counter += 3;//Увеличиваем счетчик на 3, ибо у пикселя 3 цвета, на каждый цвет по 3 байта. ЛОГИШНО? ЛОГИШНО!
    end;
    l.Add(lm);//Добавляем строчку в массив(список) строк
  end;
  Result := l;//Радуемся и возвращаем результат
end;

function SavePixels(pixels : List<List<Pixel>>) : array of byte;//Создаем из двумерного массива пикселей - одномерный массив байт этих пикселей.
var
  res : array of byte;
  currentPixel : array of byte;
  counter : integer;
begin
  res := new byte[((width*3)+additional)*height];
  foreach ps : List<Pixel> in pixels do
  begin
    foreach p : Pixel in ps do
      begin
        currentPixel := p.getBytes();
        res[counter] := currentPixel[0];
        res[counter+1] := currentPixel[1];
        res[counter+2] := currentPixel[2];
        counter += 3;
      end;
      counter += additional;
  end;
  Result := res;//Выполняем страшный метод выше
end;

function ConcatPixels(first : List<List<Pixel>>; second : List<List<Pixel>>; third : List<List<Pixel>>; orig : List<List<Pixel>>) : List<List<Pixel>>;//Соединяет 4 двумерных массива(списка) в 1. 4 картинки в одной.
var
  newPixels : List<List<Pixel>>;
  tmpList : List<Pixel>;
begin
  newPixels := new List<List<Pixel>>;//Создаем новый массив двумерный
  for i : integer := 0 to (height*2)-1 do//Ини
  begin//Циа
    tmpList := new List<Pixel>();//Лиз
    newPixels.Add(tmpList);//ируем
    for j : integer := 0 to (width*2)-1 do//Его
      tmpList.Add(new Pixel(0, 0, 0));//До талого черными пикселями
  end;
  for i : integer := 0 to height-1 do
    for j : integer := 0 to width-1 do
      newPixels[i][j] := first[i][j];//Помещаем первую картинку, кажется, сверху слева
  for i : integer := 0 to height-1 do
    for j : integer := 0 to width-1 do
      newPixels[i][j+width] := second[i][j];//Вторую справа от первой
  for i : integer := 0 to height-1 do
    for j : integer := 0 to width-1 do
      newPixels[i+height][j] := third[i][j];//Третью снизу от первой
  for i : integer := 0 to height-1 do
    for j : integer := 0 to width-1 do
      newPixels[i+height][j+width] := orig[i][j];//И последнюю под второй
  Result := newPixels;//Все это в итоге может поменяться местами за счет не того порядка. Надеюсь, что нет.
end;

begin

end. 