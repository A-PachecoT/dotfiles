%% ============================================================================
%%  xgodel-ficha.cls  —  Ficha didáctica estilo "Recursos Didácticos", marca XGodel
%%  Compilar con XeLaTeX (necesario para fontspec / fuentes del sistema).
%%
%%  Réplica de la anatomía medida sobre el PDF original:
%%    · A4 210×297 mm
%%    · Marco perimetral 3 pt a 8.5 mm del borde  (#00B0F0 → morado XGodel)
%%    · Cabecera con URL en cursiva negrita + filete fino
%%    · Cuerpo a dos columnas con filete separador central
%%    · Banner de portada con mascota, marca, grado y curso
%%    · Caja de título redondeada
%%    · Bloques "EJERCICIOS DE APLICACIÓN" / "TAREA DOMICILIARIA Nº n"
%% ============================================================================
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{xgodel-ficha}[2026/07/22 v1.0 Ficha didactica XGodel]

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions\relax
\LoadClass[a4paper,10pt]{article}

\RequirePackage{geometry}
\RequirePackage{fontspec}
\RequirePackage{xcolor}
\RequirePackage{tikz}
\RequirePackage{tcolorbox}
\RequirePackage{multicol}
\RequirePackage{enumitem}
\RequirePackage{fancyhdr}
\RequirePackage{eso-pic}
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{array}
\RequirePackage{graphicx}
\RequirePackage{ragged2e}
\RequirePackage[normalem]{ulem}

\usetikzlibrary{calc,shapes.geometric,decorations.pathmorphing}
\tcbuselibrary{skins}

% ---------------------------------------------------------------------------
%  1. PALETA XGODEL  (el original usa cian #00B0F0; aquí morado)
% ---------------------------------------------------------------------------
\definecolor{xgpurple}{HTML}{7C3AED}   % primario  — reemplaza al cian #00B0F0
\definecolor{xgdeep}{HTML}{5B21B6}     % morado profundo — títulos
\definecolor{xgink}{HTML}{3B0A6B}      % texto de acento muy oscuro
\definecolor{xglight}{HTML}{EDE9FE}    % lavanda de fondo
\definecolor{xgpale}{HTML}{F7F4FF}     % lavanda casi blanco
\definecolor{xggold}{HTML}{F5A524}     % acento cálido (pico de la mascota)

\colorlet{xgrule}{xgpurple}            % filete separador de columnas
\colorlet{xgborder}{xgpurple}          % marco perimetral

% ---------------------------------------------------------------------------
%  2. FUENTES  (idénticas al original, con alternativas libres si no existen)
% ---------------------------------------------------------------------------
\newcommand{\xg@setbody}[1]{\setmainfont{#1}[AutoFakeSlant=0.2]}

\IfFontExistsTF{Comic Sans MS}
  {\xg@setbody{Comic Sans MS}}
  {\IfFontExistsTF{Comic Neue}
     {\xg@setbody{Comic Neue}}
     {\IfFontExistsTF{TeX Gyre Adventor}
        {\xg@setbody{TeX Gyre Adventor}}
        {\xg@setbody{Latin Modern Sans}}}}

\IfFontExistsTF{Arial Black}
  {\newfontfamily\displayfont{Arial Black}[AutoFakeSlant=0.0]%
   \newfontfamily\displayslant{Arial Black}[AutoFakeSlant=0.22]}
  {\IfFontExistsTF{Archivo Black}
     {\newfontfamily\displayfont{Archivo Black}%
      \newfontfamily\displayslant{Archivo Black}[AutoFakeSlant=0.22]}
     {\newfontfamily\displayfont{TeX Gyre Heros}[UprightFont=*-Bold]%
      \newfontfamily\displayslant{TeX Gyre Heros}[UprightFont=*-Bold,AutoFakeSlant=0.22]}}

\IfFontExistsTF{Arial}
  {\newfontfamily\urlfont{Arial}[AutoFakeSlant=0.2]}
  {\newfontfamily\urlfont{TeX Gyre Heros}[AutoFakeSlant=0.2]}

% Variante espaciada para los rótulos de bloque (EJERCICIOS DE APLICACIÓN)
\IfFontExistsTF{Comic Sans MS}
  {\newfontfamily\spacedfont{Comic Sans MS}[LetterSpace=14.0]}
  {\newfontfamily\spacedfont{TeX Gyre Heros}[LetterSpace=14.0]}

% La matemática hereda la fuente del texto, como en el original (que compone
% las expresiones en la misma tipografía redondeada, no en Computer Modern).
% Debe cargarse DESPUÉS de fijar las fuentes.
\RequirePackage[defaultmathsizes,nolessnomore,noplusnominus]{mathastext}

% ---------------------------------------------------------------------------
%  3. GEOMETRÍA  (medida sobre el PDF original)
% ---------------------------------------------------------------------------
\geometry{
  a4paper,
  left=17mm, right=17mm,
  top=10mm, bottom=13mm,
  includehead, headheight=15pt, headsep=4mm,
  footskip=0pt
}

\setlength{\columnsep}{8mm}
\setlength{\columnseprule}{0.9pt}
\renewcommand{\columnseprulecolor}{\color{xgrule}}
\setlength{\parindent}{0pt}
\setlength{\parskip}{0.9ex}
\linespread{1.06}

% ---------------------------------------------------------------------------
%  4. METADATOS DE LA FICHA
% ---------------------------------------------------------------------------
\newcommand{\xg@marca}{XGodel}
\newcommand{\xg@sitio}{www.XGodel.com}
\newcommand{\xg@grado}{Primero de Secundaria}
\newcommand{\xg@curso}{Raz. Matemático}
\newcommand{\xg@titulo}{Título de la ficha}
\def\xg@mascota{}               % \def, no \newcommand: \ifx debe casar con \@empty
\newcommand{\xgbrandsize}{40}   % tamaño en pt del logotipo del banner

\newcommand{\marca}[1]{\renewcommand{\xg@marca}{#1}}
\newcommand{\sitio}[1]{\renewcommand{\xg@sitio}{#1}}
\newcommand{\grado}[1]{\renewcommand{\xg@grado}{#1}}
\newcommand{\curso}[1]{\renewcommand{\xg@curso}{#1}}
\newcommand{\titulo}[1]{\renewcommand{\xg@titulo}{#1}}
\newcommand{\mascota}[1]{\def\xg@mascota{#1}}          % ruta a imagen (opcional)

% ---------------------------------------------------------------------------
%  5. MARCO PERIMETRAL EN TODAS LAS PÁGINAS
% ---------------------------------------------------------------------------
\AddToShipoutPictureBG{%
  \begin{tikzpicture}[remember picture,overlay]
    \draw[xgborder,line width=3pt]
      ($(current page.south west)+(8.5mm,8.5mm)$)
      rectangle
      ($(current page.north east)+(-8.5mm,-8.5mm)$);
  \end{tikzpicture}%
}

% ---------------------------------------------------------------------------
%  6. CABECERA
% ---------------------------------------------------------------------------
% Portada: la URL sin filete — el banner arranca justo debajo, como en el original.
\fancypagestyle{xgodel}{%
  \fancyhf{}%
  \fancyhead[R]{\urlfont\bfseries\color{xgpurple}\footnotesize\xg@sitio}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
  \fancyhead[L]{}%
  \renewcommand{\headrule}{}%   imprescindible: xgodelint lo redefine globalmente
}
% Página interior: filete fino bajo la URL
\fancypagestyle{xgodelint}{%
  \fancyhf{}%
  \fancyhead[R]{\urlfont\bfseries\color{xgpurple}\footnotesize\xg@sitio}%
  \renewcommand{\headrulewidth}{0pt}%
  \renewcommand{\footrulewidth}{0pt}%
  \fancyhead[L]{}%
  \renewcommand{\headrule}{\color{xgpurple}\hrule height 1.1pt}%
}
\pagestyle{xgodelint}

% ---------------------------------------------------------------------------
%  7. MASCOTA POR DEFECTO (búho geométrico morado, dibujado en TikZ)
%     Se usa solo si no se definió \mascota{archivo.png}
% ---------------------------------------------------------------------------
\newcommand{\xgbuho}[1][1]{%
\begin{tikzpicture}[scale=#1,x=1mm,y=1mm,line join=round,line cap=round]
  % --- penachos (se dibujan antes y sobresalen por encima del cuerpo) ---
  \fill[white] (-7.4,6.6) -- (-3.0,14.8) -- (-9.4,10.6) -- cycle;
  \fill[white] ( 7.4,6.6) -- ( 3.0,14.8) -- ( 9.4,10.6) -- cycle;
  % --- patas ---
  \fill[xggold] (-4.4,-10.4) -- (-2.0,-10.4) -- (-2.0,-12.6) -- (-4.9,-12.6) -- cycle;
  \fill[xggold] ( 4.4,-10.4) -- ( 2.0,-10.4) -- ( 2.0,-12.6) -- ( 4.9,-12.6) -- cycle;
  % --- cuerpo ---
  \fill[white] (0,0) ellipse (9.4 and 11.2);
  \fill[xglight] (0,-3.4) ellipse (6.0 and 7.2);
  % --- alas ---
  \fill[xglight] (-8.6,-1.0) arc[start angle=90,end angle=270,x radius=2.1,y radius=5.4] -- cycle;
  \fill[xglight] ( 8.6,-1.0) arc[start angle=90,end angle=-90,x radius=2.1,y radius=5.4] -- cycle;
  % --- antifaz y ojos ---
  \fill[white] (-3.7,4.5) circle (3.9);
  \fill[white] ( 3.7,4.5) circle (3.9);
  \draw[xgdeep,line width=0.8mm] (-3.7,4.5) circle (3.9);
  \draw[xgdeep,line width=0.8mm] ( 3.7,4.5) circle (3.9);
  \fill[xgink] (-3.7,4.5) circle (1.9);
  \fill[xgink] ( 3.7,4.5) circle (1.9);
  \fill[white] (-3.0,5.3) circle (0.68);
  \fill[white] ( 4.4,5.3) circle (0.68);
  % --- pico ---
  \fill[xggold] (0,2.6) -- (-1.8,-0.4) -- (1.8,-0.4) -- cycle;
  % --- libro abierto, por delante del cuerpo ---
  \fill[white] (-9.8,-7.0) -- (0,-5.0) -- (0,-10.6) -- (-9.8,-12.0) -- cycle;
  \fill[white] ( 9.8,-7.0) -- (0,-5.0) -- (0,-10.6) -- ( 9.8,-12.0) -- cycle;
  \draw[xgdeep,line width=0.45mm]
       (-9.8,-7.0) -- (0,-5.0) -- (9.8,-7.0) -- (9.8,-12.0) -- (0,-10.6) -- (-9.8,-12.0) -- cycle;
  \draw[xgdeep,line width=0.55mm] (0,-5.0) -- (0,-10.6);
  \draw[xgpurple,line width=0.3mm] (-8.2,-8.2) -- (-1.6,-6.9);
  \draw[xgpurple,line width=0.3mm] (-8.2,-9.7) -- (-1.6,-8.4);
  \draw[xgpurple,line width=0.3mm] ( 8.2,-8.2) -- ( 1.6,-6.9);
  \draw[xgpurple,line width=0.3mm] ( 8.2,-9.7) -- ( 1.6,-8.4);
\end{tikzpicture}}

% ---------------------------------------------------------------------------
%  8. BANNER DE PORTADA
% ---------------------------------------------------------------------------
\newcommand{\xgbanner}{%
\noindent
\begin{tikzpicture}[x=1mm,y=1mm]
  \pgfmathsetmacro{\W}{\textwidth/2.845276}   % ancho del texto, en mm
  \pgfmathsetmacro{\Hb}{38}                    % alto del banner, en mm
  \pgfmathsetmacro{\Mx}{25}                    % ancho reservado a la mascota
  \begin{scope}
    \clip (0,0) rectangle (\W,\Hb);
    \fill[xgpurple] (0,0) rectangle (\W,\Hb);
    % cuña blanca superior (inclinada)
    \fill[white] (-3,34.4) -- (\W+3,37.6) -- (\W+3,\Hb+3) -- (-3,\Hb+3) -- cycle;
    % franja blanca separadora entre filas
    \fill[white] (-3,16.2) -- (\W+3,19.4) -- (\W+3,17.6) -- (-3,14.4) -- cycle;
    % placa izquierda (grado)
    \fill[white] (\Mx,2.6) -- (0.545*\W,2.6) -- (0.545*\W+3.2,13.2) -- (\Mx+3.2,13.2) -- cycle;
    % placa derecha (curso)
    \fill[white] (0.605*\W,2.6) -- (\W-3.4,2.6) -- (\W-0.2,13.2) -- (0.605*\W+3.2,13.2) -- cycle;
  \end{scope}

  % --- mascota ---
  \node[anchor=west,inner sep=0pt] at (0.5,18) {%
    \ifx\xg@mascota\@empty
      \xgbuho[1.28]%
    \else
      \includegraphics[height=35mm]{\xg@mascota}%
    \fi};

  % --- logotipo de la marca ---
  \node[anchor=center,inner sep=0pt,text=white] at ({(\Mx+\W)/2},26.4)
    {\displayslant\fontsize{\xgbrandsize}{\xgbrandsize}\selectfont \MakeUppercase{\xg@marca}};

  % --- grado y curso ---
  \node[anchor=center,inner sep=0pt,text=xgpurple] at ({(\Mx+0.545*\W)/2+1.6},7.9)
    {\displayslant\fontsize{13}{13}\selectfont \MakeUppercase{\xg@grado}};
  \node[anchor=center,inner sep=0pt,text=xgpurple] at ({(0.605*\W+\W)/2+1.6},7.9)
    {\displayslant\fontsize{13}{13}\selectfont \MakeUppercase{\xg@curso}};
\end{tikzpicture}\par
}

% ---------------------------------------------------------------------------
%  9. CAJA DE TÍTULO
% ---------------------------------------------------------------------------
\newcommand{\xgtitulo}{%
  \begin{center}
  \begin{tcolorbox}[
      enhanced, sharp corners=all, rounded corners, arc=4mm,
      colback=xgpale, colframe=xglight, boxrule=0.8pt,
      interior style={left color=white, right color=xglight},
      width=0.86\textwidth, halign=center, valign=center,
      top=3mm, bottom=3mm, left=4mm, right=4mm,
      drop fuzzy shadow=xglight
    ]
    {\displayfont\fontsize{21}{24}\selectfont\color{xgdeep}\MakeUppercase{\xg@titulo}}
  \end{tcolorbox}
  \end{center}
}

% Portada completa: banner + título, y arranque de las dos columnas
\newcommand{\portada}{%
  \thispagestyle{xgodel}%
  \xgbanner
  \vspace{-1mm}
  \xgtitulo
  \vspace{-2mm}
}

% ---------------------------------------------------------------------------
%  10. BLOQUES DE CONTENIDO
% ---------------------------------------------------------------------------

% ● CONCEPTO subrayado  (equivalente a "OPERACIÓN MATEMÁTICA" del original)
% El subrayado se corta por línea para que los títulos largos no desborden
% la columna (ulem no rompe dentro de \uline si el texto va en una sola caja).
\newcommand{\concepto}[1]{%
  \par\medskip
  {\raggedright\bfseries
   \setlength{\hangindent}{5.2mm}\setlength{\hangafter}{1}%
   \noindent
   \raisebox{0.22ex}{\tikz[baseline]{\fill[xgpurple] (0,0.6ex) circle (0.9mm);
                                     \fill[white] (0.35mm,0.95ex) circle (0.28mm);}}%
   \hspace{2mm}\MakeUppercase{\uline{#1}}\par}
  \smallskip
}

% Enumeración de apartados teóricos: 1. MEDIANTE FÓRMULA
\newlist{apartados}{enumerate}{1}
\setlist[apartados]{label=\arabic*.,labelsep=3mm,leftmargin=7mm,
                    itemsep=1.6ex,topsep=1.2ex,parsep=0.6ex}
\newcommand{\rotulo}[1]{{\bfseries\uline{\MakeUppercase{#1}}}\par\smallskip}

% Banner de sección: EJERCICIOS DE APLICACIÓN / TAREA DOMICILIARIA
\newcommand{\bloque}[1]{%
  \par\vspace{3mm}
  \begin{tcolorbox}[
      enhanced, sharp corners=all, rounded corners, arc=2.6mm,
      colback=white, colframe=xgpurple, boxrule=1.6pt,
      halign=center, valign=center,
      top=1.4mm, bottom=1.4mm, left=1mm, right=1mm,
      before skip=1mm, after skip=3mm
    ]
    {\spacedfont\fontsize{11}{13}\selectfont\MakeUppercase{#1}}
  \end{tcolorbox}
}
\newcommand{\tarea}[1]{\bloque{Tarea Domiciliaria N\textsuperscript{o} #1}}

% Lista de ejercicios
\newlist{ejercicios}{enumerate}{1}
\setlist[ejercicios]{label=\arabic*.,labelsep=3mm,leftmargin=7mm,
                     itemsep=2.2ex,topsep=0.8ex,parsep=0.7ex}

% Alternativas a)…e) en rejilla de 3 columnas, como el original
% \tabcolsep a 0: con el valor por defecto (6 pt) las dos separaciones internas
% añaden 24 pt y la rejilla desborda la columna.
\newcommand{\alts}[5]{%
  \par\smallskip
  \noindent
  \setlength{\tabcolsep}{0pt}%
  \begin{tabular}{@{}p{0.33\linewidth}p{0.33\linewidth}p{0.33\linewidth}@{}}
    a) #1 & b) #2 & c) #3 \\[0.7ex]
    d) #4 & e) #5 &        \\
  \end{tabular}%
  \par
}

% Líneas punteadas para que el alumno escriba
\newcommand{\lineas}[1]{%
  \par\smallskip
  \begingroup
  \setlength{\parskip}{0pt}%
  \newcount\xg@n \xg@n=#1\relax
  \loop\ifnum\xg@n>0
    \noindent\hspace*{3mm}%
    \leaders\hbox to 0.62em{\hss.\hss}\hfill\null\par\vspace{2.4mm}%
    \advance\xg@n by -1
  \repeat
  \endgroup
  \par\smallskip
}

% Globo de diálogo (contorno continuo) y de pensamiento (contorno punteado)
\newtcolorbox{globo}[1][]{
  enhanced, sharp corners=all, rounded corners, arc=3.5mm,
  colback=white, colframe=black, boxrule=1.1pt,
  halign=center, fontupper=\small,
  top=2mm, bottom=2mm, left=2.5mm, right=2.5mm, #1
}
% Globo de pensamiento: contorno punteado (tcolorbox no admite `dash pattern`
% directamente; se dibuja con borderline sobre un marco invisible).
\newtcolorbox{pensamiento}[1][]{
  enhanced, sharp corners=all, rounded corners, arc=3.5mm,
  colback=white, colframe=white, boxrule=0pt,
  borderline={1.1pt}{0pt}{black, dash pattern=on 1.1pt off 2.2pt},
  halign=center, fontupper=\small,
  top=2mm, bottom=2mm, left=2.5mm, right=2.5mm, #1
}

% Caja de fórmula destacada
\newcommand{\formula}[1]{%
  \par\smallskip
  \begin{center}
  \begin{tcolorbox}[enhanced, sharp corners, colback=white, colframe=black,
                    boxrule=0.9pt, width=0.9\linewidth, halign=center,
                    top=1.6mm, bottom=1.6mm]
    #1
  \end{tcolorbox}
  \end{center}
  \par\smallskip
}

% Tabla de Cayley (operación definida por tabla)
%   \begin{cayley}{4}  $\ast$ & a & b & c & d \\ \cline{2-5} ... \end{cayley}
\newenvironment{cayley}[1]{%
  \par\smallskip\centering
  \renewcommand{\arraystretch}{1.25}%
  \begin{tabular}{@{}c!{\color{xgrule}\vrule width 1.1pt}*{#1}{>{\centering\arraybackslash}p{7.5mm}}@{}}
}{%
  \end{tabular}\par\smallskip
}

% Tabla con rejilla completa (como algunos ejercicios del original)
\newenvironment{cayleyfull}[1]{%
  \par\smallskip\centering
  \renewcommand{\arraystretch}{1.3}%
  \begin{tabular}{|c|*{#1}{>{\centering\arraybackslash}p{7.5mm}|}}\hline
}{%
  \end{tabular}\par\smallskip
}

% Símbolo de operador genérico (el original usa un cuadrado)
\newcommand{\op}{\mathbin{\text{\raisebox{0.05ex}{$\scriptstyle\square$}}}}

% Operador dentro de triángulo, como en el original
\newcommand{\triop}[1]{%
  \tikz[baseline=(n.base)]{
    \node[regular polygon, regular polygon sides=3, draw, inner sep=0.35mm,
          minimum size=6.5mm, line width=0.5pt] (n) {\scriptsize #1};}%
}

% Arranque / cierre del cuerpo a dos columnas
\newenvironment{ficha}{\begin{multicols}{2}}{\end{multicols}}

\endinput
