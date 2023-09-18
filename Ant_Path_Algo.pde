PVector[] cities;          // Array to store city coordinates
int totalCities = 15;      // Number of cities
Ant[] ants;                // Array to store ants
int totalAnts = 100;       // Number of ants

PVector[] bestPath;        // Array to store the best path found so far
float bestDistance;        // Best distance found so far
float updateInterval = 10.0;  // Update interval in seconds
float lastUpdateTime;     // Time when the last update occurred

float[][] pheromones;      // Pheromone levels on edges
float evaporationRate = 0.9;  // Rate at which pheromones evaporate
float initialPheromone = 0.5; // Initial pheromone level
float alpha = 25.0;        // You can adjust the value of alpha
float beta = 1.0;          // You can adjust the value of beta

PVector selectedCity = null;   // Store the selected city for dragging
boolean citiesAvailable = false;   // Flag to check if cities are available
boolean mouseClickedFinished = true;   // Flag to check if the mouse click event is finished
PVector[] citiesToAdd = new PVector[0]; // Array to store cities to be added

PVector startCity;          // Starting city
PVector endCity;            // Ending city

void setup() {
  size(1080, 1080);
  frameRate(5);
  cities = new PVector[totalCities];
  ants = new Ant[totalAnts];
  bestPath = new PVector[totalCities];
  pheromones = new float[totalCities][totalCities];

  initializeCities(); // A new function to initialize cities

  // Create ants
  for (int i = 0; i < totalAnts; i++) {
    ants[i] = new Ant();
  }

  bestDistance = calcTotalDistance(bestPath);
  lastUpdateTime = millis() / 1000.0; // Initialize the last update time
}

void initializeCities() {
  for (int i = 0; i < totalCities; i++) {
    cities[i] = new PVector(random(width), random(height));
    bestPath[i] = cities[i].copy();
    for (int j = 0; j < totalCities; j++) {
      pheromones[i][j] = initialPheromone;
    }
  }

  // Initialize the starting and ending cities
  startCity = cities[int(random(totalCities))];
  endCity = cities[int(random(totalCities))];
}

void draw() {
  background(255);

  // Check if it's time to update the ants
  float currentTime = millis() / 1000.0;
  if (currentTime - lastUpdateTime >= updateInterval) {
    lastUpdateTime = currentTime;

    // Find the best path using ants
    for (Ant ant : ants) {
      ant.findPath();
    }

    // Update the best path
    for (Ant ant : ants) {
      if (ant.getRouteLength() < bestDistance) {
        bestDistance = ant.getRouteLength();
        bestPath = ant.getPath();
      }
    }
  }

  // Display cities
  fill(255, 0, 0);
  for (PVector city : cities) {
    ellipse(city.x, city.y, 25, 25);
  }

  // Display best path
  stroke(0);
  strokeWeight(10);
  noFill();
  beginShape();
  for (PVector city : bestPath) {
    vertex(city.x, city.y);
  }
  endShape(CLOSE);

  // Display pheromone trails
  for (int i = 0; i < totalCities; i++) {
    for (int j = i + 1; j < totalCities; j++) {
      if (i >= 0 && i < totalCities && j >= 0 && j < totalCities) {
        float pheromone = pheromones[i][j];
        float pheromoneSize = map(pheromone, 0, initialPheromone, 1, 5);
        stroke(0, 0, 255);
        strokeWeight(pheromoneSize);
        line(cities[i].x, cities[i].y, cities[j].x, cities[j].y);
      }
    }
  }
}

float calcTotalDistance(PVector[] path) {
  float total = 0;
  for (int i = 0; i < path.length - 1; i++) {
    total += dist(path[i].x, path[i].y, path[i + 1].x, path[i + 1].y);
  }
  return total;
}

void mouseClicked() {
  if (mouseX >= 0 && mouseX < width && mouseY >= 0 && mouseY < height) {
    // Check if a city is clicked for dragging
    boolean cityClicked = false;
    for (PVector city : cities) {
      float d = dist(mouseX, mouseY, city.x, city.y);
      if (d < 10) { // Adjust the radius for selecting cities
        selectedCity = city;
        cityClicked = true;
        break;
      }
    }

    // If no city is clicked and there's no city to be added, add a new city
    if (!cityClicked && citiesToAdd.length == 0) {
      PVector newCity = new PVector(mouseX, mouseY);
      // Add the new city to the array
      citiesToAdd = (PVector[]) append(citiesToAdd, newCity);
    }
  }
}

void mouseDragged() {
  // Move the selected city with the mouse
  if (selectedCity != null) {
    selectedCity.x = mouseX;
    selectedCity.y = mouseY;
  }
}

void mouseReleased() {
  // Stop dragging when the mouse is released
  selectedCity = null;
}

class Ant {
  PVector[] path;
  boolean[] visited;
  int currentIndex; // Track the current index in the path array
  float routeLength; // Length of the current route

  Ant() {
    path = new PVector[totalCities];
    visited = new boolean[totalCities];
    routeLength = 0;

    // Initialize the starting and ending cities
    path[0] = startCity;
    path[totalCities - 1] = endCity;
    visited[cities.indexOf(startCity)] = true;
    visited[cities.indexOf(endCity)] = true;
    currentIndex = 0; // Initialize the current index

    // Initialize the rest of the path array to random city locations
    for (int i = 1; i < totalCities - 1; i++) {
      int randomCityIndex;
      do {
        randomCityIndex = int(random(totalCities));
      } while (visited[randomCityIndex]); // Ensure the city hasn't been visited
      path[i] = cities[randomCityIndex].copy();
      visited[randomCityIndex] = true;
    }
  }

  void findPath() {
    while (currentIndex < totalCities - 1) {
      int nextCity = selectNextCity(currentIndex);
      if (nextCity == -1) {
        // No valid city found, break the loop
        break;
      }
      currentIndex++;
      PVector current = path[currentIndex - 1];
      PVector next = path[currentIndex];
      routeLength += dist(current.x, current.y, next.x, next.y);
    }

    // Reset ant for the next iteration
    for (int i = 0; i < totalCities; i++) {
      visited[i] = false;
    }
    path[0] = startCity;
    path[totalCities - 1] = endCity;
    visited[cities.indexOf(startCity)] = true;
    visited[cities.indexOf(endCity)] = true;
    currentIndex = 0; // Reset the current index
    routeLength = 0; // Reset the route length
  }

  int selectNextCity(int currentIndex) {
    float[] probabilities = new float[totalCities];
    float total = 0;

    for (int i = 0; i < totalCities; i++) {
      if (!visited[i] && i != currentIndex) { // Exclude the current city
        float pheromone = pheromones[currentIndex][i];
        float distance = dist(path[currentIndex].x, path[currentIndex].y, cities[i].x, cities[i].y);
        probabilities[i] = pow(pheromone, alpha) / pow(distance, beta);
        total += probabilities[i];
      }
    }

    if (total == 0) {
      return -1; // No valid city found
    }

    float randomValue = random(total);
    float cumulative = 0;
    int nextCity = -1; // Initialize nextCity as -1

    for (int i = 0; i < totalCities; i++) {
      if (!visited[i] && i != currentIndex) {
        cumulative += probabilities[i];
        if (cumulative >= randomValue) {
          nextCity = i; // Set nextCity to the selected city
          break; // Exit the loop once a city is selected
        }
      }
    }

    return nextCity; // Return the selected city
  }

  void display() {
    stroke(0, 255, 0);
    strokeWeight(2);
    noFill();
    beginShape();
    for (PVector city : path) {
      vertex(city.x, city.y);
    }
    endShape();
  }

  PVector[] getPath() {
    return path;
  }

  float getRouteLength() {
    return routeLength;
  }
}

PVector[] copyPVectorArray(PVector[] source) {
  PVector[] copy = new PVector[source.length];
  for (int i = 0; i < source.length; i++) {
    copy[i] = new PVector(source[i].x, source[i].y);
  }
  return copy;
}
