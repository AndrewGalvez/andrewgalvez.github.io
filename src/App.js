import { useState, useEffect } from 'react';

function GameBoxImage({ gamedata }) {
  return (
      <div className = "game-box-img">
	<img src={process.env.PUBLIC_URL + gamedata.imgpath}/>

    </div>
  );
}

function GameBoxDescButton({path, desc, d}) {
  return (
	  <a   {...(d && { download: true })} target="_blank" href={path} ><button disabled={
	    path === "none"
	  }>{desc}</button></a>
  );
}

function GameBoxDesc({ gamedata }) {
  return (
      <div className = "game-box-desc">
    <p>
	  { gamedata.name}
    </p>
    {gamedata.dev && <p className= "game-box-desc-dev">
      In Development
    </p>}
	  <GameBoxDescButton path={gamedata.githubpath} desc={"Source Code"}/>
	  <GameBoxDescButton d={true} path={gamedata.downloadlinux} desc={"Download for Linux"}/>
	  <GameBoxDescButton d={true} path={gamedata.downloadwindows} desc={"Download For Windows"}/>
    </div>
  );
}

function GameBox({ gamedata }) {
  return (
    <div className= "game-box" id={gamedata.name} >
      <GameBoxImage gamedata={gamedata}/>
      <GameBoxDesc gamedata ={gamedata}/>
    </div>
  );
};

function GameBoxesWrapper({games_data}) {
  return (
    <div className="game-boxes-wrapper">
      {games_data.map((game, i) => <GameBox gamedata={game}/>)}
    </div>);
};

function SidebarSearchPrompt({searchTerm}) {
  return (<input placeholder="Find a game..." value={searchTerm}/>);
}

function SidebarItemList({games_data}) {
  return (
    <ul>
      {games_data.map((game, i) => <li key={i}><a href={`#${game.name}`}>{game.name}</a></li>)}
    </ul>
  );
}

function Sidebar({data}) {
 return (<div className="sidebar">
   {/* <p><b>Search</b></p> <SidebarSearchPrompt/>  */}
   <SidebarItemList games_data={data}/> </div>);
}

function Header({setFeedback}) {
  return (
    <div className="header">
      <div className="feedback-button">
	<button id="feedback-button" onClick={setFeedback}>Feedback</button>
      </div>
    </div>
  );
}

function FeedbackPanel({runSendFeedback}) {
  const [text, setText] = useState('');

  const sendFeedback = () => {
    runSendFeedback(text);
  }

  return (
    <div className="feedback-panel">
      <div className="feedback-panel-main">
      <textarea onChange={e => setText(e.target.value)}/>
      <button onClick={sendFeedback}>Send</button>
    </div>
    <div className="feedback-panel-right">
    <h3>Feedback</h3>
    <ul>
    <li>Bugs</li>
    <li>Comments</li>
    <li>Suggestions</li>
    </ul>
    <p>Thanks for sending feedback!</p>
    </div>
    </div>
  );
}

function FeaturedGames({gamesdata}) {
  return (<div className="featured-games">
    <center>
    <h1 className="fg-header">Featured Games</h1>
    </center>
    <GameBoxesWrapper 
    games_data = {gamesdata.slice(gamesdata.length - 2, gamesdata.length)}
    />
    </div>);
}

function App() {
  const [games_data, setGamesData] = useState([]);
  useEffect(() => {
    fetch(process.env.PUBLIC_URL + '/games.json')
      .then(res => res.json())
      .then(data => setGamesData(data))
  }, []);

  const [isFeedbackDisplayed, setIsFeedbackDisplayed] = useState(false);

  function sendFeedback(text) {
    window.location.href = "mailto:dogisamoose.amazon@gmail.com?subject=Feedback&body="+text;
  };

  return (<>
    <Header setFeedback={()=>{setIsFeedbackDisplayed(!isFeedbackDisplayed);}}/>
    {isFeedbackDisplayed && <FeedbackPanel runSendFeedback={sendFeedback}/>}
    <div className="mainwrapper">
    <Sidebar data={games_data}/>
    <div className="gameswrapper">
    <FeaturedGames gamesdata={games_data}/>
    <GameBoxesWrapper className="game-boxes-wrapper" games_data={games_data}/>
    </div>
    </div>
    </>);
}

export default App;
