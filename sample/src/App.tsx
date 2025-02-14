import './App.css'

function App() {
  const appName = import.meta.env.VITE_APP_NAME || 'World';
  return (
    <div className="main-container">
      {/* Efecto de resplandor de fondo */}
      <div className="glow"></div>
      
      {/* Contenedor del texto neón */}
      <div className="neon-container">
        <h1 className="neon-text">
          <span className="hello-text">Hello!</span>
          <span className="world-text">{appName}</span>
        </h1>
      </div>
    </div>
  )
}
export default App;
