import "./App.css"
import Sketch from "./Sketch"
import { Canvas } from "@react-three/fiber"

function App() {
  return (
    <div className='App'>
      <Canvas
        camera={{
          position: [0, 0, 15],
        }}
      >
        <ambientLight intensity={0.2} />
        <pointLight position={[0, 1, 5]} intensity={1.0} />

        <Sketch />
      </Canvas>
    </div>
  )
}

export default App
