program test;

uses BMP, NoiseFunc;


const
  SOURCE = 'example.bmp';//Оригинал картинки
  FIRST = 'newA.bmp';
  SECOND = 'newB.bmp';
  THIRD = 'newC.bmp';
  OUTPUT = 'output.bmp';

var
  pixelsRawArray : array of byte;//Необработанный массив пикселей
  BMPHeader : array of byte;
  glassPixels, wavePixels, randomPixels, blurPixels : List<List<Pixel>>;//Списки строчек. Список хранит строчки. Строчка хранит список пикселей этой строчки. По сути двумерный массив [кол-во строчек, кол-во пикселей в строчке]
  orig, np, wave, blur, all : List<List<Pixel>>;//Пиксели, подверженные какому-либо эффекту. orig - хранит необработанные пиксели, как они и были в оригинальном файле example.bmp
  f : File;
  
procedure SaveToFile(pixels : array of byte; Filename : String);
var
  ff : File;
begin
  Assign(ff, Filename);
  Rewrite(ff);
  for i : integer := 0 to BMPHeader.Length-1 do
    Write(ff, BMPHeader[i]);
  Seek(ff, BMP.WIDTH_OFFSET);
  Write(ff, BMP.width);
  Seek(ff, BMP.HEIGHT_OFFSET);
  Write(ff, BMP.height);
  Seek(ff, BMP.SIZEIMAGE_OFFSET);
  Write(ff, BMP.sizeimage);
  Seek(ff, BMP.pixelsOffset);
  for i : integer := 0 to pixels.Length-1 do
    Write(ff, pixels[i]);
  Close(ff);
end;
begin
  if(not FileExists(SOURCE))
  then begin
    WriteLn('File ' + SOURCE + ' does not exist');
    exit;//То выходим
  end;
  Assign(f, SOURCE);
  Reset(f);
  Read(f, BMP.typeNum);
  if (not BMP.typeNum = 19778) AND 
     (not BMP.typeNum = 16973) then
  begin
    WriteLn('This is not BMP file! Fail');
    exit();//Это не БМП
  end;
  Seek(f, BMP.PIXELS_OFFSET);
  Read(f, BMP.pixelsOffset);
  Seek(f, BMP.WIDTH_OFFSET);
  Read(f, BMP.width);
  Seek(f, BMP.HEIGHT_OFFSET);
  Read(f, BMP.height);
  Seek(f, BMP.BIT_COUNT_OFFSET);
  Read(f, BMP.bitCount);
  if(BMP.bitCount <> 24) then
  begin
    WriteLn('Only BMP-24');
    exit;
  end;
  Seek(f, BMP.SIZEIMAGE_OFFSET);
  Read(f, BMP.sizeimage);
  pixelsRawArray := new byte[BMP.sizeimage];
  Seek(f, BMP.pixelsOffset);
  for i : integer := 0 to BMP.sizeimage-1 do
    Read(f, pixelsRawArray[i]);
  BMPHeader := new byte[BMP.pixelsOffset];
  Seek(f, 0);
  for i : integer := 0 to BMP.pixelsOffset-1 do
    Read(f, BMPHeader[i]);
  Close(f);
  BMP.additional := BMP.width mod 4;
  WriteLn('Width = ', BMP.width, ' | Height = ', BMP.height);//Выводим инфу о размерах
  orig := BuildPixels(pixelsRawArray);//Строим пиксели. Создаем запись(По сути объект структуры/класса).
  glassPixels := BuildPixels(pixelsRawArray);
  wavePixels := BuildPixels(pixelsRawArray);
  randomPixels := BuildPixels(pixelsRawArray);
  blurPixels := BuildPixels(pixelsRawArray);//Делаем все то же самое, в последствии эти пиксели будут меняться, поэтому не допускаем работы над одним набором пикселей несколько раз. Получится наложение и в итоге - параша.
  var glassCoeff, waveCoeff, ranCoeff, blurCoeff : integer;//Переменные, которые хранят значения, выбранные пользователем для каждого метода.
 Write('Enter glass coefficient: ');//Приглашаем к вводу
  repeat
    try//Блок исключений
      ReadLn(glassCoeff);//Ожидаем ввод
    except
      on Exception do//На любое исключение
        WriteLn('This is an invalid value! Try again.');//Говорим, что вы не правы, сударь, повторите плес.
    end;
  until glassCoeff <> 0;//До тех пор повторяем все этоп, пока glassCoeff = 0;
  Write('Enter wave coefficient: ');//Тут тоже самое
    repeat
    try
      ReadLn(waveCoeff);
    except
      on Exception do
        WriteLn('This is an invalid value! Try again.');
    end;
  until waveCoeff <> 0;
    Write('Enter randomWave coefficient: ');//Тут тоже самое
    repeat
    try
      ReadLn(ranCoeff);
    except
      on Exception do
        WriteLn('This is an invalid value! Try again.');
    end;
  until ranCoeff <> 0;
      Write('Enter blur division: ');//Тут тоже самое
    repeat
    try
      ReadLn(blurCoeff);
    except
      on Exception do
        WriteLn('This is an invalid value(default: 16)! Try again.');
    end;
  until blurCoeff <> 0;
  np := NoiseFunc.GetGlassNoise(glassPixels, glassCoeff);//Получаем пиксели с эффектом стекла
  pixelsRawArray := BMP.SavePixels(np);//Впихиваем все эти объединенные пиксели в байты картинки
  SaveToFile(pixelsRawArray, FIRST);
  wave := NoiseFunc.GetWaveNoise(wavePixels, waveCoeff);//То же самое
  pixelsRawArray := BMP.SavePixels(wave);//Впихиваем все эти объединенные пиксели в байты картинки
  SaveToFile(pixelsRawArray, SECOND);
  //ran := NoiseFunc.GetRandomWave(randomPixels, ranCoeff);//То же самое
  blur := NoiseFunc.GetBlur(blurPixels, blurCoeff);//То же самое
  pixelsRawArray := BMP.SavePixels(blur);//Впихиваем все эти объединенные пиксели в байты картинки
  SaveToFile(pixelsRawArray, THIRD);
  all := BMP.ConcatPixels(np, wave, blur, orig);//Объединяем 4 набора пикселей в один набор
  BMP.width *= 2;//При этом меняем параметры изображения. Удваиваем длину
  BMP.height *= 2;//Высоту
  BMP.additional := BMP.width mod 4;//Вычисляем смещение строчки. Сколько байтов должно быть в строке
  BMP.totalPixelsBytesCount := ((BMP.width*3)+additional)*BMP.height;//Вычисляем, сколько всего должно быть байтов после заголовков BMP
  BMP.sizeimage := BMP.totalPixelsBytesCount;
  pixelsRawArray := BMP.SavePixels(all);//Впихиваем все эти объединенные пиксели в байты картинки
  SaveToFile(pixelsRawArray, OUTPUT);
end.