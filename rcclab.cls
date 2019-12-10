%% Class rcclab
%% Adapted from the nature class https://www.ctan.org/tex-archive/macros/latex/contrib/nature/
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{rcclab}[10/12/2019 v1.0]
\typeout{A class for writing RCCLab manuscripts}
\typeout{Written by Ryan Chiechi}
\typeout{ }

\LoadClass[12pt]{article}
% \RequirePackage{biblatex}
\RequirePackage{stix}
\RequirePackage{hyperref}
\RequirePackage{fullpage}
\RequirePackage{graphicx}
\RequirePackage{ifthen}

%% make labels in bibliobraphy be #.
\renewcommand\@biblabel[1]{#1.}

%% make citations be superscripts, taken from citesupernumber.sty
\def\@cite#1#2{$^{\mbox{\scriptsize #1\if@tempswa , #2\fi}}$}

%% Some style parameters
\setlength{\parindent}{0.39in}
\setlength{\parskip}{18pt}
\newcommand{\spacing}[1]{\renewcommand{\baselinestretch}{#1}\large\normalsize}
\spacing{2}

%% Redefine \maketitle for RCCLab style
\def\@maketitle{%
  \newpage\spacing{1}\setlength{\parskip}{12pt}%
    {\Large\bfseries\noindent\sloppy \textsf{\@title} \par}%
    {\noindent\sloppy \@author}%
}

%%Define \maketitlesi for RCCLab style
\newcommand\maketitlesi{\@maketitlesi}
\def\@maketitlesi{%
  \newpage\spacing{1}\setlength{\parskip}{12pt}%
    {\Large\bfseries\noindent\sloppy Supporting Information for: \textsf{\@title} \par}%
    {\noindent\sloppy \@author}%
}
  % \ifx\acs@manuscript\acs@manuscript@suppinfo
  % \setkeys{acs}{maxauthors = 0}
  % \def\thepage{S-\arabic{page}}
  % \renewcommand*\thefigure{S\@arabic\c@figure}
  % \renewcommand*\thescheme{S\@arabic\c@scheme}
  % \renewcommand*\thetable{S\@arabic\c@table}
  % \AtBeginDocument
  %   {%
  %     \renewcommand*\citenumfont[1]{S#1}%
  %     \renewcommand*\bibnumfmt[1]{(S#1)}%
  %   }

%% Define the affiliations environment, list each institution as an \item
%% Put after \maketitle
\newenvironment{affiliations}{%
    \setcounter{enumi}{1}%
    \setlength{\parindent}{0in}%
    \slshape\sloppy%
    \begin{list}{\upshape$^{\arabic{enumi}}$}{%
        \usecounter{enumi}%
        \setlength{\leftmargin}{0in}%
        \setlength{\topsep}{0in}%
        \setlength{\labelsep}{0in}%
        \setlength{\labelwidth}{0in}%
        \setlength{\listparindent}{0in}%
        \setlength{\itemsep}{0ex}%
        \setlength{\parsep}{0in}%
        }
    }{\end{list}\par\vspace{12pt}}

%% Redefine the abstract environment to be the first centered paragraph
% \renewenvironment{abstract}{%
%     \setlength{\parindent}{0in}%
%     \setlength{\parskip}{0in}%
%     \centering%
%     }{\par\vspace{-6pt}}

\renewenvironment{abstract}{%
  % \hrule
  %\vspace{2 mm}%
% \sffamily
  \noindent
  \emph{\textbf{Abstract:}}%
}{%
  %\vspace{2 mm}%
  % \hrule
  \vspace{6 mm}%
}


%% Redefine the \section command.
\renewcommand{\section}{\@startsection {section}{1}{0pt}%
    {-6pt}{1pt}%
    {\bfseries}%
    }
\renewcommand{\subsection}{\@startsection {subsection}{2}{0pt}%
    {-0pt}{-0.5em}%
    {\bfseries}*%
    }

%% Define the methods environment.  Use \subsection to separate.
\newenvironment{methods}{%
    \section*{Methods}%
    \setlength{\parskip}{12pt}%
    }{}

%% Define the experimental environment.  Use \subsection to separate.
\newenvironment{experimental}{%
    \section*{Experimental}%
    \setlength{\parskip}{12pt}%
    }{}

%% No heading for References section, but eat up the extra space from \section command
\renewcommand\refname{\vspace{-48pt}\setlength{\parskip}{12pt}}

%% Define the addendum environment for Supplementary Info, Acknowledgements, etc.
\newenvironment{addendum}{%
    \setlength{\parindent}{0in}%
    \small%
    \begin{list}{Acknowledgements}{%
        \setlength{\leftmargin}{0in}%
        \setlength{\listparindent}{0in}%
        \setlength{\labelsep}{0em}%
        \setlength{\labelwidth}{0in}%
        \setlength{\itemsep}{12pt}%
        \let\makelabel\addendumlabel}
    }
    {\end{list}\normalsize}

\newcommand*{\addendumlabel}[1]{\textbf{#1}\hspace{1em}}
