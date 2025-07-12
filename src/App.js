import { useState, useEffect } from 'react';

function GameBox({ gamedata }) {
  return (
    <div className= "game-box">
      <div className = "game-box-img">
	<img src={gamedata.imgpath}/>

    </div>
      <div className = "game-box-desc">
    <p>
	  { gamedata.name }
    </p>
	  <a target="_blank" href={gamedata.githubpath} ><button disabled={
	    gamedata.githubpath === "none"
	  }>Source Code</button></a>
	  <a download href={gamedata.downloadlinux}><button disabled={
	    gamedata.downloadlinux === "none"}>Download for Linux</button></a>
	  <a download href={gamedata.downloadwindows}><button disabled={
	    gamedata.downloadwindows === "none"}>Download for Windows</button></a>
    </div>
    </div>
  );
};

function GameBoxesWrapper({games_data}) {
  return (
    <ul className="game-boxes-wrapper">
      {games_data.map((game, i) => <li key={i}><GameBox gamedata={game}/></li>)}
    </ul>);
};

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

function App() {
  const [games_data, setGamesData] = useState([]);
  useEffect(() => {
    fetch('/games.json')
      .then(res => res.json())
      .then(data => setGamesData(data))
  }, []);

  const [isFeedbackDisplayed, setIsFeedbackDisplayed] = useState(false);

  function sendFeedback(text) {
    console.log(text);
    window.location.href = "mailto:dogisamoose.amazon@gmail.com?subject=Feedback&body="+text;
  };

  return (<>
    <Header setFeedback={()=>{setIsFeedbackDisplayed(!isFeedbackDisplayed);}}/>
    {isFeedbackDisplayed && <FeedbackPanel runSendFeedback={sendFeedback}/>}
    <GameBoxesWrapper className="game-boxes-wrapper" games_data={games_data}/>
    </>);
}

export default App;
