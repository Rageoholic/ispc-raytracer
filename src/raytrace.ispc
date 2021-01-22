typedef float<3> v3;

float square(float a)
{
  return a * a;
}

struct Hit
{
  v3 p;
  v3 n;
  float t;
};

struct Sphere
{
  v3 o;
  float r;
};

struct ExternSphere
{
  float o[3];
  float r;
};

struct Ray
{
  v3 p;
  // NOTE: direction must be unit length
  v3 dir;
};

v3 V3(float a, float b, float c)
{
  v3 ret = {a, b, c};
  return ret;
}

uniform v3 V3(uniform float a, uniform float b, uniform float c)
{
  uniform v3 ret = {a, b, c};
  return ret;
}

v3 crossProduct(v3 a, v3 b)
{
  return V3(a[1] * b[2] - b[1] * a[2],
            a[2] * b[0] - b[2] * a[0],
            a[0] * b[1] - b[1] * a[0]);
}

float dotProduct(v3 a, v3 b)
{
  float sum = 0;
  for(int i = 0; i < 3; i++)
  {
    sum += a[i] * b[i];
  }
  return sum;
}

v3 pointAtDistance(Ray r, float t)
{
  return r.p + t * r.dir;
}

float squareLen(v3 v)
{
  float square_len = 0;
  for(int i = 0; i < 3; i++)
  {
    square_len += square(v[i]);
  }
  return square_len;
}

v3 fastNormalizeV3(v3 v)
{
  float square_len = squareLen(v);
  if(square_len > 0)
  {
    float rlen = rsqrt_fast(square_len);
    return v * rlen;
  } else
  {
    v3 ret = {0, 0, 0};
    return ret;
  }
}

int32 v3ToSRGBColor(v3 c)
{
  int32<3> ic = {float_to_srgb8(c.r), float_to_srgb8(c.g), float_to_srgb8(c.b)};
  return 0xFF000000 | (ic.r << 16) | (ic.g << 8) | (ic.b << 0);
}

int32 v3ToLinearColor(v3 c)
{
  int32<3> ic = (int32<3>)(c * 255);
  return 0xFF000000 | (ic.r << 16) | (ic.g << 8) | (ic.b << 0);
}

v3 lerpV3(v3 a, v3 b, float t)
{
  return t * a + (1 - t) * b;
}

bool hitSphere(Sphere s, Ray r, varying Hit *uniform hit)
{
  v3 oc = r.p - s.o;
  float a = squareLen(r.dir);
  float half_b = dotProduct(oc, r.dir);
  float c = dotProduct(oc, oc) - square(s.r);
  float discriminant = square(half_b) - a * c;
  if(discriminant < 0)
  {
    return false;
  } else
  {
    // This ignores the back face implicitly and so if you're *in* a sphere
    // you will be able to see out
    float t = (-half_b - sqrt(discriminant)) / (a);
    if(t > .001)
    {
      v3 p = pointAtDistance(r, t);
      v3 n = fastNormalizeV3(p - s.o);
      hit->p = p;
      hit->n = n;
      hit->t = t;
      return true;
    } else
    {
      return false;
    }
  }
}

uniform Sphere externSphereToSphere(uniform ExternSphere s)
{
  uniform Sphere ret = {V3(s.o[0], s.o[1], s.o[2]), s.r};
  return ret;
}

v3 rayColor(Ray r,
            uniform size_t sphere_count,
            uniform const ExternSphere spheres[])
{
  float t = r.dir.y / 2 + .5;
  v3 white = {1, 1, 1};
  v3 blue = {0.25, 0.63, 1};
  v3 background = lerpV3(blue, white, t);

  Hit h;
  v3 col = background;
  float min_t = 10000;
  for(uniform size_t i = 0; i < sphere_count; i++)
  {
    uniform Sphere s = externSphereToSphere(spheres[i]);
    if(hitSphere(s, r, &h) && h.t < min_t)
    {
      col = h.n;
      min_t = h.t;
    }
  }
  return col * .5 + .5;
}

extern "C" void printSizeT(size_t s);

export void raytraceIspc(uniform uint32 width,
                         uniform uint32 height,
                         uniform unsigned int bitmap[],
                         uniform size_t sphere_count,
                         uniform const ExternSphere spheres[])
{
  float focal_length = 1;
  float aspect = (float)(width) / (float)(height);
  float view_width = 2;
  float view_height = view_width / aspect;
  v3 horizontal = {view_width, 0, 0};
  v3 vertical = {0, view_height, 0};
  v3 upper_left_corner =
      0 + vertical / 2 - horizontal / 2 - V3(0, 0, focal_length);

  for(uniform uint32 y = 0; y < height; y++)
  {
    foreach(x = 0...width)
    {
      int index = y * width + x;
      float u = (float)x / (float)(width - 1);
      float v = (float)y / (float)(height - 1);

      Ray r = {
          {0, 0, 0},
          fastNormalizeV3(upper_left_corner + horizontal * u - vertical * v)};
      v3 col = rayColor(r, sphere_count, spheres);
      bitmap[index] = v3ToSRGBColor(col);
    }
  }
}

export void squareBuf(uniform uint32 count,
                      uniform const float inbuf[],
                      uniform float outbuf[])
{
  foreach(i = 0...count)
  {
    outbuf[i] = square(inbuf[i]);
  }
}

export void pow2Buf(uniform uint32 count,
                    uniform const float inbuf[],
                    uniform float outbuf[])
{
  foreach(i = 0...count)
  {
    outbuf[i] = pow(inbuf[i], 2);
  }
}
